#!/bin/bash

if [ -f service.pid ]; then
    echo "Service already running!"
    exit 1
fi

cmd_args=$@
env=${1:-default}

jvm_xms=${2:-2g}
jvm_xmx=${3:-2g}
new_size=128m
if [ "$env" = "prod" ]; then
    jvm_xms=${2:-15g}
    jvm_xmx=${3:-15g}
    new_size=3g
fi

hostname=`hostname -I | cut -d' ' -f1`

jvm_args="-Xms${jvm_xms} -Xmx${jvm_xmx} -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:NewSize=${new_size} -XX:+CMSParallelRemarkEnabled -Djava.net.preferIPv4Stack=true -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=1099 -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=${hostname} -verbosegc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps
-XX:-HeapDumpOnOutOfMemoryError -XX:OnOutOfMemoryError=./restart.sh"
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
    echo ${cmd_args} > service.args
else
    echo "Failed to start Service in env: $env"
    rm -f service.pid
    rm -f service.args
    exit 1
fi
