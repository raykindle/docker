# 1 构建pycharm远程镜像
## 1.1 构建docker remote镜像
```bash
screen -S pycharm_remote
docker build -t harbor.in-clustar.ai:8443/lianzhu/raykindle_remote_jupyter:pt1.10 /nfs/wenjun/ai_stable/docker

# Docker 时区调整方案: https://cloud.tencent.com/developer/article/1626811
```

## 1.3 启动镜像(远程)
```bash
# (推荐)
ssh -L 19508:127.0.0.1:19508 centos@172.16.0.163
# 指定容器的工作目录: 启动容器时传入-w <work_dir>参数
export DATA_DIR=/nfs/wenjun
export WORK_DIR=/nfs/wenjun/ai_stable/deploy/lianzhu/deploy
docker run --gpus all --shm-size=187g \
    -v ${DATA_DIR}:${DATA_DIR} \
    -e TZ=Asia/Shanghai \
    -w ${WORK_DIR} \
    -p 19922:22 -p 19988:8888 -p 19506:6006 -p 19508:8080 \
    -t harbor.in-clustar.ai:8443/lianzhu/raykindle_remote_jupyter:pt1.10


export DATA_DIR=/nfs/wenjun
docker run --gpus all --shm-size=187g \
    -v ${DATA_DIR}:${DATA_DIR} \
    -e TZ=Asia/Shanghai \
    -p 19522:22 -p 19588:8888 -p 19506:6006 -p 19508:8080 \
    -t harbor.in-clustar.ai:8443/jsl/raykindle_remote_jupyter:pt1.6_tf2

nvidia-docker run --runtime=nvidia -e NVIDIA_VISIBLE_DEVICES=0,1,2,3 --shm-size 187G -v /nfs/wenjun:/nfs/wenjun -p 19522:22 -p 19506:6006 -p 19588:8888 -p 19508:8080 -t harbor.in-clustar.ai:8443/jsl/raykindle_remote_jupyter:pt1.6


export DATA_DIR=/nfs/wenjun
export WORK_DIR=/nfs/wenjun/open_src/mmsegmentation
docker run --gpus all --shm-size=187g \
    -v ${DATA_DIR}:${DATA_DIR} \
    -e TZ=Asia/Shanghai \
    -w ${WORK_DIR} \
    -t harbor.in-clustar.ai:8443/lianzhu/raykindle_remote_jupyter:pt1.10

```

