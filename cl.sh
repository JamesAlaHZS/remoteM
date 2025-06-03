#!/bin/bash
# 设置cron定时任务
(crontab -l 2>/dev/null; echo "*/1 * * * * /usr/bin/clear") | crontab -
echo "已设置每分钟自动清屏任务"
echo "停止请运行: crontab -r"#!/bin/bash

