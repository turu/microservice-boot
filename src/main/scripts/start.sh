#!/bin/bash

if [ -f service.pid ]; then
    echo "Service already running!"
    exit 1
fi

cmd_args=$@
env=${1:-default}

jvm_xms=${2:-@jvmArgs.dev.xms@}
jvm_xmx=${3:-@jvmArgs.dev.xmx@}
new_size=@jvmArgs.dev.newSize@
gc_args="@jvmArgs.dev.gc@"
jmx_args="@jvmArgs.dev.jmx@"
if [ "$env" = "prod" ]; then
    jvm_xms=${2:-@jvmArgs.prod.xms@}
    jvm_xmx=${3:-@jvmArgs.prod.xmx@}
    new_size=@jvmArgs.prod.newSize@
    gc_args="@jvmArgs.prod.gc@"
    jmx_args="@jvmArgs.prod.jmx@"
fi

hostname=`hostname -I | cut -d' ' -f1`

jvm_args="-Xms${jvm_xms} -Xmx${jvm_xmx} -XX:NewSize=${new_size} -Djava.net.preferIPv4Stack=true -Djava.rmi.server.hostname=${hostname} \
-XX:+HeapDumpOnOutOfMemoryError -XX:OnOutOfMemoryError=./restart.sh ${gc_args} ${jmx_args}"
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
