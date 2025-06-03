apt update -y
sudo apt install libuv1 libuv1-dev -y
sudo apt install libhwloc-dev hwloc  -y# 安装最新版 hwloc :cite[3]:cite[6]
# 若已安装其他版本（如 libhwloc.so.10）
sudo ln -s /usr/lib/libhwloc.so.10 /usr/lib/libhwloc.so.15
sudo ldconfig
id1=87CdGvxKktVNebisEHVzNwCjPeS54wrPkBAMuGViHNDMjWBU4hwoubRLagcxFEUo2K5kcJ4QSVanEPag9UDr4s9bQSYQ4hz
id2=125fka2fSVTvhv6dSTzMWQNN3ZBLWZNQLneH8BKqLH8aYUANvVFtLWL7457cQnCfMvXuSizBaH5k5b6DnmupCiPdjjG
port=61180
pool1=ala168.cn:431
pool2=ala168.cn:6118
proxy = ala168.cn:61180 
apt update -y; apt install screen -y;
sudo apt install nvidia-opencl-dev  -y
chmod u+x SRBMiner-MULTI
chmod u+x xmrig

screen -S xmrig -X quit
screen -S xmrig ./xmrig -a rx/0 --url $pool1  --user  $id1 -k -p $(hostname) --donate-level 0

screen -S tari -X quit
screen -S tari ./SRBMiner-MULTI --algorithm sha3x --pool $pool2 --wallet $id2.$(hostname)



