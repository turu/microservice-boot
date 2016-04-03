#!/bin/bash
# This script starts a microservice-boot app.
# Usage: ./start.sh [<env={default,prod}>] [<app_port:@app.port@>] [<xms:{@jvmArgs.dev.xms@,@jvmArgs.prod.xms@}>] [<xmx:{@jvmArgs.dev.xmx@,@jvmArgs.prod.xmx@}>] [<extra_args>]

if [ -f service.pid ]; then
    echo "Service already running!"
    exit 1
fi

cmd_args=$@
env=${1:-default}

app_port=${2:-@app.port@}

# Find hostname and available JMX port
hostname=`hostname -I | cut -d' ' -f1`

jmx_port=1099
is_free=$(netstat -tapln | grep ${jmx_port})
tries=0

while [[ -n "${is_free}" || "${jmx_port}" = "${app_port}" && tries < 1000 ]]; do
    jmx_port=$[jmx_port+1]
    tries=$[tries+1]
    is_free=$(netstat -tapln | grep ${jmx_port})
done

if [[ -n "${is_free}" || "${jmx_port}" == "${app_port}" ]]; then
    echo "Failed to find available port for JMX endpoint"
    exit 2
fi

# Compose JVM (GC, JMX) parameters
jvm_xms=${3:-@jvmArgs.dev.xms@}
jvm_xmx=${4:-@jvmArgs.dev.xmx@}
gc_args="@jvmArgs.dev.gc@"
jmx_args="@jvmArgs.dev.jmx@"
if [ "$env" = "prod" ]; then
    jvm_xms=${3:-@jvmArgs.prod.xms@}
    jvm_xmx=${4:-@jvmArgs.prod.xmx@}
    gc_args="@jvmArgs.prod.gc@"
    jmx_args="@jvmArgs.prod.jmx@"
fi
gc_args="${gc_args} -XX:+HeapDumpOnOutOfMemoryError -XX:OnOutOfMemoryError=./restart.sh"
jmx_args="${jmx_args} -Djava.rmi.server.hostname=${hostname} -Dcom.sun.management.jmxremote.port=${jmx_port}"
jvm_args="-Xms${jvm_xms} -Xmx${jvm_xmx} -Dserver.port=${app_port} -Djava.net.preferIPv4Stack=true ${gc_args} ${jmx_args}"

shift 4
extra_args=$@

# Start JVM
set -o xtrace
nohup java ${jvm_args} -jar @name@-@project.version@.jar --spring.profiles.active=${env} ${extra_args} > std.out &
set +o xtrace

pid=$!
sleep 25

# Verify that service running
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
