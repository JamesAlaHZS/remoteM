# 终止thunder和thunder2进程
pkill -f thunder
pkill -f thunder2
# 可选：等待进程完全退出
sleep 1
# 执行你的qd.sh脚本（使用绝对路径）
./qd.sh
