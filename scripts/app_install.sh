#!/bin/bash
set -e

#print input parameters
echo ${app_types}

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

for app in $(echo ${app_types} | sed "s/,/ /g")
do
    if [ "$app" == "kafka_broker" ]; then
        export KAFKA_ADVERTISED_LISTENERS="INSIDE://:19092,OUTSIDE://$(curl http://169.254.169.254/latest/meta-data/public-ipv4):9092"
        export KAFKA_LISTENERS="INSIDE://:19092,OUTSIDE://:9092"
        export KAFKA_LISTENER_SECURITY_PROTOCOL_MAP="INSIDE:PLAINTEXT,OUTSIDE:PLAINTEXT"
        export KAFKA_INTER_BROKER_LISTENER_NAME="INSIDE"

        cmd=$cmd"(kafka-server-start /etc/kafka/server.properties 2>&1 > /var/log/kafka.log  &); sleep 5;"
    elif [ "$app" == "zookeeper_node" ]; then
        cmd=$cmd"(zookeeper-server-start /etc/kafka/zookeeper.properties > /var/log/zookeeper.log &); sleep 5;"
    else
        echo "Invalid application type: $app"
        exit 1
    fi
done

EXCLUSIONS="|KAFKA_VERSION|KAFKA_HOME|KAFKA_DEBUG|KAFKA_GC_LOG_OPTS|KAFKA_HEAP_OPTS|KAFKA_JMX_OPTS|KAFKA_JVM_PERFORMANCE_OPTS|KAFKA_LOG|KAFKA_OPTS|"

# Read in env as a new-line separated array. This handles the case of env variables have spaces and/or carriage returns. See #313
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
        updateConfig "$kafka_name" "$${!env_var}" "/etc/kafka/server.properties"
    fi

    if [[ $env_var =~ ^LOG4J_ ]]; then
        log4j_name=$(echo "$env_var" | tr '[:upper:]' '[:lower:]' | tr _ .)
        updateConfig "$log4j_name" "$${!env_var}" "/etc/kafka/log4j.properties"
    fi
done

# put cmd to /etc/rc.local so it can start when system reboot
echo "$cmd" >> /etc/rc.local
# execute command
eval "$cmd"

