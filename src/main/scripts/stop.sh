#!/bin/bash

pid=`cat service.pid`

if [ ! -z "$pid" ]; then
    echo "Stopping service under PID: $pid"
    kill -9 $pid
    if [ "$?" = "0" ]; then
        echo "Successfully stopped service"
        rm service.pid
    else
        echo "Failed to stop service"
    fi
else
    echo "Failed to read PID of the running instance of service"
fi