FROM nvcr.io/nvidia/pytorch:21.08-py3
MAINTAINER zhangwenjun@clustar.ai

ARG DEBIAN_FRONTEND=noninteractive
ENV TORCH_CUDA_ARCH_LIST="6.0 6.1 7.0 7.5 8.0 8.6+PTX" \
    TORCH_NVCC_FLAGS="-Xfatbin -compress-all" \
    CMAKE_PREFIX_PATH="$(dirname $(which conda))/../" \
    FORCE_CUDA="1" \
    TZ=Asia/Shanghai

# (Optional)
# RUN sed -i 's/http:\/\/archive.ubuntu.com\/ubuntu\//http:\/\/mirrors.aliyun.com\/ubuntu\//g' /etc/apt/sources.list && \
#    pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

## change the system source for installing libs
##ARG USE_SRC_INSIDE=false
##RUN if [ ${USE_SRC_INSIDE} == true ] ; \
##    then \
##        sed -i s/archive.ubuntu.com/mirrors.aliyun.com/g /etc/apt/sources.list ; \
##        sed -i s/security.ubuntu.com/mirrors.aliyun.com/g /etc/apt/sources.list ; \
##        echo "Use aliyun source for installing libs" ; \
##    else \
##        echo "Keep the download source unchanged" ; \
##    fi

# change the system source for installing libs
RUN sed -i s/archive.ubuntu.com/mirrors.aliyun.com/g /etc/apt/sources.list \
 && sed -i s/security.ubuntu.com/mirrors.aliyun.com/g /etc/apt/sources.list

# change the python source for installing libs
RUN pip install -U pip -i https://pypi.tuna.tsinghua.edu.cn/simple \
 && pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

RUN apt-get update \
    && apt-get install -y openssh-server tree expect ffmpeg libsm6 libxext6 git ninja-build libglib2.0-0 libxrender-dev zip htop screen libgl1-mesa-glx \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 配置ssh密钥
# -----------------
# ssh server（Configure SSHD: apt-get install -y openssh-server）
RUN mkdir -p /var/run/sshd
RUN echo 'root:root' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
# -----------------


# 配置jupyter
# -----------------
WORKDIR /nfs/wenjun
#COPY __init__.py /opt/conda/lib/python3.7/site-packages/traitlets/utils
COPY requirements.txt ./requirements.txt
COPY generate.sh /root/generate.sh
COPY auto_pexpect.sh ./auto_pexpect.sh
RUN ["chmod", "+x", "/root/generate.sh"]
RUN ["chmod", "+x", "./auto_pexpect.sh"]
RUN ./auto_pexpect.sh
# 每个RUN命令都会产生自己的 shell，当 shell 退出时，那个 shell 的环境就会消失。如果您需要在运行时提供此信息，您可以将其放入文件中，然后在容器启动时使用入口点脚本再次设置它。或者直接 && 接着运行
RUN password=$(cat /root/.jupyter/jupyter_notebook_config.json | python -c "import sys, json; print(json.load(sys.stdin)['NotebookApp']['password'])") \
 && echo "c.NotebookApp.password = u'$password'" >> /root/.jupyter/jupyter_notebook_config.py \
 && echo "c.NotebookApp.ip = '*'" >> /root/.jupyter/jupyter_notebook_config.py \
 && echo "c.NotebookApp.open_browser = False" >> /root/.jupyter/jupyter_notebook_config.py \
 && echo "c.NotebookApp.port = 8888" >> /root/.jupyter/jupyter_notebook_config.py \
 && echo "c.NotebookApp.notebook_dir = u'.'" >> /root/.jupyter/jupyter_notebook_config.py \
 && echo "c.NotebookApp.token = 'simon'" >> /root/.jupyter/jupyter_notebook_config.py
RUN ./auto_pexpect.sh

## 本地mac操作
## 1、本地终端ssh连接gpu3服务器时，将服务器的19688端口重定向到本地mac上
#ssh -L 19588:127.0.0.1:19588 centos@172.16.0.163
#
## 2、本地mac上浏览器输入以下链接即可打开jupyter notebook
#http://172.16.0.163:19588/tree
# -----------------


# Install MMEngine , MMCV and MMDet
RUN pip install --no-cache-dir openmim && \
    mim install --no-cache-dir "mmengine>=0.3.0" "mmcv>=2.0.0rc1,<2.1.0" "mmdet>=3.0.0rc2,<3.1.0"

# Install other python libs
RUN pip install --no-cache-dir -r ./requirements.txt

# Install MMYOLO
RUN git clone https://github.com/open-mmlab/mmyolo.git /mmyolo && \
    cd /mmyolo && \
    mim install --no-cache-dir -e .

WORKDIR /mmyolo
EXPOSE 22
ENTRYPOINT ["/root/generate.sh"]
#CMD /usr/sbin/sshd -D && tail -F /dev/null
