#!/bin/bash
# 启动jupyter
nohup jupyter notebook --ip=0.0.0.0 --allow-root &

# 启动密码服务
/usr/sbin/sshd -D && tail -F /dev/null
echo "success run"
