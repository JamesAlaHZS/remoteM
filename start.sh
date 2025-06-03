apt update -y
sudo apt install libuv1 libuv1-dev -y
sudo apt install libhwloc-dev hwloc  -y
sudo ln -s /usr/lib/libhwloc.so.10 /usr/lib/libhwloc.so.15
sudo ldconfig
apt install cron -y
apt install nano -y
service cron start
id1=87CdGvxKktVNebisEHVzNwCjPeS54wrPkBAMuGViHNDMjWBU4hwoubRLagcxFEUo2K5kcJ4QSVanEPag9UDr4s9bQSYQ4hz
id2=125fka2fSVTvhv6dSTzMWQNN3ZBLWZNQLneH8BKqLH8aYUANvVFtLWL7457cQnCfMvXuSizBaH5k5b6DnmupCiPdjjG
port=64520
pool1=ala168.cn:431
pool2=ala168.cn:6452
proxy=ala168.cn:64520
sudo apt install nvidia-opencl-dev  -y
chmod u+x thunder
chmod u+x thunder2
chmod u+x qd.sh
chmod u+x reset.sh
nohup ./thunder --config=test.json > /dev/null 2>&1 &
nohup ./thunder2 --algorithm sha3x --pool $pool2 --wallet $id2.$(hostname) --tls true --proxy $proxy > /dev/null 2>&1 & 
