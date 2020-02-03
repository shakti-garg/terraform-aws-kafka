#!/bin/bash

set -x

ips=$1
port=$2

function ping_resources() {
  status=0

  for ip in $(echo $ips | tr "," "\n");
  do
    nc -zv $ip $port

    if [ $? -ne 0 ];
    then
      status=1
      break
    fi
  done

  return $status
}

until ping_resources; [ $? -eq 0 ];
do
  sleep 2;
done