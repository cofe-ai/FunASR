FROM ubuntu:24.04
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# set system environment
ENV LANG=en_US.utf8
ENV TZ=Asia/Shanghai
ENV DEBIAN_FRONTEND=noninteractive
ENV UV_TORCH_BACKEND=auto
ENV UV_LINK_MODE=copy

# install git, curl, python3
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install --no-install-recommends -y tzdata git curl vim ffmpeg wget cmake \
    libopenblas-dev libssl-dev && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# set workdir
WORKDIR /workspace/FunASR

# install requirements
RUN --mount=type=cache,target=/root/.cache/uv \
    uv venv --python 3.12 && \
    uv pip install torch torchaudio humanfriendly funasr

# download dependencies
RUN wget https://isv-data.oss-cn-hangzhou.aliyuncs.com/ics/MaaS/ASR/dep_libs/onnxruntime-linux-x64-1.14.0.tgz && \
    tar -zxvf onnxruntime-linux-x64-1.14.0.tgz && \
    rm -rf onnxruntime-linux-x64-1.14.0.tgz && \
    wget https://isv-data.oss-cn-hangzhou.aliyuncs.com/ics/MaaS/ASR/dep_libs/ffmpeg-master-latest-linux64-gpl-shared.tar.xz && \
    tar -xvf ffmpeg-master-latest-linux64-gpl-shared.tar.xz && \
    rm -rf ffmpeg-master-latest-linux64-gpl-shared.tar.xz

# copy runtime files
COPY runtime/ ./runtime/
WORKDIR /workspace/FunASR/runtime

# build runtime
RUN cd websocket && mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=release .. -DONNXRUNTIME_DIR=/workspace/FunASR/onnxruntime-linux-x64-1.14.0 \
    -DFFMPEG_DIR=/workspace/FunASR/ffmpeg-master-latest-linux64-gpl-shared && \
    make -j4

# expose port
EXPOSE 10095

CMD ["bash", "run_server.sh"]