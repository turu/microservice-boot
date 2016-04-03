#!/bin/bash

if [ ! -f service.pid ]; then
    echo "Service is not running. Cannot restart!"
    exit 1
fi
cmd_args=`cat service.args`

./stop.sh
sleep 20
./start.sh ${cmd_args}
