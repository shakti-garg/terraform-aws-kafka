#!/bin/bash

set -x

#print input parameters
echo ${region}
echo ${kafka_autoscaling_group_name}
echo ${num_brokers}
echo ${zookeeper_quorum}
echo ${num_embedded_zks}

function install_confluent() {
    yum update -y
    yum install curl which
    yum install -y java
    rpm --import https://packages.confluent.io/rpm/5.3/archive.key

    echo '
[Confluent.dist]
name=Confluent repository (dist)
baseurl=https://packages.confluent.io/rpm/5.3/7
gpgcheck=1
gpgkey=https://packages.confluent.io/rpm/5.3/archive.key
enabled=1

[Confluent]
name=Confluent repository
baseurl=https://packages.confluent.io/rpm/5.3
gpgcheck=1
gpgkey=https://packages.confluent.io/rpm/5.3/archive.key
enabled=1
    ' > /etc/yum.repos.d/confluent.repo

    yum clean all -y && yum install -y confluent-community-2.12
}

function updateConfig() {
    key=$1
    value=$2
    file=$3

    # Omit $value here, in case there is sensitive information
    echo "[Configuring] '$key' in '$file'"

    # If config exists in file, replace it. Otherwise, append to file.
    if grep -E -q "^#?$key=" "$file"; then
        sed -r -i "s@^#?$key=.*@$key=$value@g" "$file" #note that no config values may contain an '@' char
    else
        echo "$key=$value" >> "$file"
    fi
}

echo "Installing Confluent Platform - Community Edition..."
install_confluent

ZK_CFG="/etc/kafka/zookeeper.properties"
BROKER_CFG="/etc/kafka/server.properties"
LOG4J_CFG="/etc/kafka/log4j.properties"

# wait for hostname creation due to delay in DNS resolution
while [ -z "$myHostname" ] ; do
  sleep 3
  myHostname=$(hostname)
done

#wait for all brokers to be running
aws ec2 describe-instances --output text --region "${region}" \
  --filters 'Name=instance-state-name,Values=running' \
  --query 'Reservations[].Instances[].[InstanceId,PrivateDnsName,AmiLaunchIndex,LaunchTime,Placement.AvailabilityZone,Tags[?Key == `aws:autoscaling:groupName`] | [0].Value ] ' \
  | grep -w "${kafka_autoscaling_group_name}" | sort -k 3 -k 4 -k 5 \
  | awk '{print $1" "$2}' > /tmp/brokers

while [ $(cat /tmp/brokers | wc -l) != "${num_brokers}" ]
do
    sleep 5

    aws ec2 describe-instances --output text --region "${region}" \
      --filters 'Name=instance-state-name,Values=running' \
      --query 'Reservations[].Instances[].[InstanceId,PrivateDnsName,AmiLaunchIndex,LaunchTime,Placement.AvailabilityZone,Tags[?Key == `aws:autoscaling:groupName`] | [0].Value ] ' \
      | grep -w "${kafka_autoscaling_group_name}" | sort -k 3 -k 4 -k 5 \
      | awk '{print $1" "$2}' > /tmp/brokers
done

#if embedded zookeeper quorum is required to be deployed
if [ "${zookeeper_quorum}" = "" ] ; then
  head -n ${num_embedded_zks} /tmp/brokers > /tmp/zookeepers

  myid=0
  zkid=1
  while read znode
  do
    #create quorum url
    if [ -z "$zkconnect" ] ; then
      zkconnect="$znode:2181"
    else
      zkconnect="$zkconnect,$znode:2181"
    fi

    [ $znode = $myHostname ] && myid=$zkid

    zkServers=$zkServers"\n""server.$zkid=$znode:2888:3888"

    zkid=$[zkid+1]
  done <<< $(awk '{print $2}' /tmp/zookeepers)

  if [ $myid -gt 0 ] ; then
    #configure embedded zookeeper and prepare execution command
    grep -q ^initLimit "$ZK_CFG"
    [ $? -ne 0 ] && echo "initLimit=5" >> "$ZK_CFG"

    grep -q ^syncLimit "$ZK_CFG"
    [ $? -ne 0 ] && echo "syncLimit=2" >> "$ZK_CFG"

    echo -e "$zkServers" >> "$ZK_CFG"

    echo $myid > /var/lib/zookeeper/myid

    myApps=$myApps" zookeeper-node"

    cmd=$cmd"(zookeeper-server-start $ZK_CFG > /var/log/zookeeper.log &); sleep 5;"
  fi
else
  zkconnect=${zookeeper_quorum}
fi


#configure broker and prepare execution command
export KAFKA_ZOOKEEPER_CONNECT="$zkconnect"
export KAFKA_ADVERTISED_LISTENERS="INSIDE://:19092,OUTSIDE://$(curl http://169.254.169.254/latest/meta-data/public-ipv4):9092"
export KAFKA_LISTENERS="INSIDE://:19092,OUTSIDE://:9092"
export KAFKA_LISTENER_SECURITY_PROTOCOL_MAP="INSIDE:PLAINTEXT,OUTSIDE:PLAINTEXT"
export KAFKA_INTER_BROKER_LISTENER_NAME="INSIDE"

myid=-1
bkid=0
while read brokerInstanceId brokerHost
do
  if [ $brokerHost = $myHostname ] ; then
    myid=$bkid;
    myInstanceId=$brokerInstanceId;
    myApps=$myApps" kafka-broker"
  fi

  bkid=$[bkid+1]
done < <(cat /tmp/brokers)

export KAFKA_BROKER_ID="$myid"

cmd=$cmd"(kafka-server-start $BROKER_CFG 2>&1 > /var/log/kafka.log  &); sleep 5;"

# Tag the instance
appsVal=$(echo $myApps | awk '{$1=$1;print}' | sed 's/ /,/g')

aws ec2 create-tags --region "${region}" --resources $myInstanceId --tags \
Key=Name,Value="${kafka_autoscaling_group_name}-broker-$myid" \
Key=Apps,Value="'$appsVal'"

# Read in env as a new-line separated array.
EXCLUSIONS="|KAFKA_VERSION|KAFKA_HOME|KAFKA_DEBUG|KAFKA_GC_LOG_OPTS|KAFKA_HEAP_OPTS|KAFKA_JMX_OPTS|KAFKA_JVM_PERFORMANCE_OPTS|KAFKA_LOG|KAFKA_OPTS|"
IFS=$'\n'
for VAR in $(env)
do
    env_var=$(echo "$VAR" | cut -d= -f1)
    if [[ "$EXCLUSIONS" = *"|$env_var|"* ]]; then
        echo "Excluding $env_var from config"
        continue
    fi

    if [[ $env_var =~ ^KAFKA_ ]]; then
        kafka_name=$(echo "$env_var" | cut -d_ -f2- | tr '[:upper:]' '[:lower:]' | tr _ .)
        updateConfig "$kafka_name" "$${!env_var}" "$BROKER_CFG"
    fi

    if [[ $env_var =~ ^LOG4J_ ]]; then
        log4j_name=$(echo "$env_var" | tr '[:upper:]' '[:lower:]' | tr _ .)
        updateConfig "$log4j_name" "$${!env_var}" "$LOG4J_CFG"
    fi

    if [[ $env_var =~ ^ZOOKEEPER_ ]]; then
        zk_name=$(echo "$env_var" | tr '[:upper:]' '[:lower:]' | tr _ .)
        updateConfig "$zk_name" "$${!env_var}" "$ZK_CFG"
    fi
done

# put cmd to /etc/rc.local so it can start when system reboot
echo "$cmd" >> /etc/rc.local
# execute command
eval "$cmd"

