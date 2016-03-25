#!/bin/bash

if [ -f service.pid ]; then
    echo "Service already running!"
    exit 1
fi

env=${1:-default}

jvm_xms=${2:-2g}
jvm_xmx=${3:-2g}
new_size=128m
if [ "$env" = "prod" ]; then
    jvm_xms=${2:-15g}
    jvm_xmx=${3:-15g}
    new_size=3g
fi

jvm_args="-Xms${jvm_xms} -Xmx${jvm_xmx} -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:NewSize=${new_size} -XX:MaxNewSize=${new_size} -XX:CMSInitiatingOccupancyFraction=50 -XX:+CMSParallelRemarkEnabled -Djava.net.preferIPv4Stack=true"
shift 3
extra_args=$@

set -o xtrace
nohup java ${jvm_args} -jar @name@-@project.version@.jar --spring.profiles.active=${env} ${extra_args} > std.out &
set +o xtrace

pid=$!
sleep 25
is_running=`netstat -pan | grep "$pid"`
if [ ! -z "$is_running" ]; then
    echo "Service successfully started in env: $env. PID: $pid"
    echo ${pid} > service.pid
else
    echo "Failed to start service in env: $env"
    rm -f service.pid
    exit 1
fi
