#!/bin/bash

pid=`cat service.pid`

if [ ! -z "$pid" ]; then
    echo "Stopping Service under PID: $pid"
    kill -9 $pid
    if [ "$?" = "0" ]; then
        echo "Successfully stopped Service"
        rm service.pid
        rm service.args
    else
        echo "Failed to stop Service"
    fi
else
    echo "Failed to read PID of the running instance of Service"
fi
