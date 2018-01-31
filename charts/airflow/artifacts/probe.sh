#!/bin/bash
if [ $(ps aux | grep scheduler | wc -l) -lt 2 ]; then
    exit 1
fi
