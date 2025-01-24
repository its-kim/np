FROM ubuntu:focal

ENV DEBIAN_FRONTEND noninteractive

VOLUME /ffmpeg/dist

RUN apt-get update ; \
    apt-get -y install wget curl unzip build-essential libtool pkg-config cmake autoconf automake libtool pkg-config yasm gperf uuid texinfo ;\
    mkdir -p /ffmpeg/src

# NVIDIA Video Encoder SDK
COPY nvenc_sdk_8.0.14/nvEncodeAPI.h /usr/include/

#
COPY msdk-18781d3b.tgz /ffmpeg/src/
COPY build-ffmpeg.sh /ffmpeg/src/build.sh
CMD cd /ffmpeg/src ; ./build.sh /ffmpeg/dist/
