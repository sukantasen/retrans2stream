#FROM nvidia/cuda:11.0-cudnn8-devel-ubuntu20.04
#FROM nvidia/cuda:11.0-cudnn8-devel-ubuntu18.04-rc
FROM nvidia/cuda:10.1-devel-ubuntu16.04

MAINTAINER Sukanta Sen <sukantasen10@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt install -y software-properties-common && add-apt-repository ppa:deadsnakes/ppa
RUN apt-get update && apt-get install --no-install-recommends -y \
    cmake \
    wget \
    libboost-dev \
    libboost-all-dev \
    gfortran \
    zlib1g-dev \
    g++ \
    automake \
    autoconf \
    libtool \
    libgoogle-perftools-dev \
    libxml2-dev \
    libxslt1-dev \
    socat \
    python3-dev \
    python3.7 \
    python3.7-dev \
    python3-setuptools \
    checkinstall \
    libreadline-gplv2-dev \
    libncursesw5-dev \
    libsqlite3-dev \
    tk-dev \
    libffi-dev \
    libssl-dev \
    libgdbm-dev \
    libc6-dev \
    libbz2-dev \
    zlib1g-dev \
    libffi-dev \
    build-essential \
    parallel \
    git \
    vim \
    python3 \
    python3-pip \
&& rm -rf /var/lib/apt/lists/* && ldconfig -v

#WORKDIR /tmp
#RUN wget https://github.com/Kitware/CMake/releases/download/v3.16.5/cmake-3.16.5.tar.gz &&  tar -zxvf cmake-3.16.5.tar.gz &&  cd cmake-3.16.5 &&  ./bootstrap &&  make  install

# download MKL so we can also run Marian on CPU
#RUN wget -qO- 'https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB' | apt-key add - \
#    && sh -c 'echo deb https://apt.repos.intel.com/mkl all main > /etc/apt/sources.list.d/intel-mkl.list' \
#    && apt-get update \
#    && apt-get install --no-install-recommends -y intel-mkl-64bit-2020.0-088

COPY ./model /mt/model
COPY ./Makefile /mt/Makefile
WORKDIR /mt
RUN make tools

RUN apt-get update && apt-get install -y build-essential git python3 python3-pip libsndfile1
RUN git clone https://github.com/pytorch/fairseq.git /mt/tools/fairseq
RUN python3.7 -m pip install -U  pip
RUN python3.7 -m pip install  torch torchaudio soundfile sentencepiece sacrebleu=="1.5.1"
WORKDIR /mt/tools/fairseq
RUN python3.7 -m pip install -e .
RUN git clone https://github.com/facebookresearch/SimulEval.git /mt/tools/SimulEval
WORKDIR /mt/tools/SimulEval
RUN python3.7 -m pip install -e .
#RUN ln -s /usr/bin/python3.7 /usr/bin/python
RUN python3.7 -m pip install https://github.com/kpu/kenlm/archive/master.zip
RUN python3.7 -m pip install websocket websocket-client

#COPY ./agent/agent.py /mt/agent/.
#COPY ./Dockerfile ./entrypoint.sh ./run.sh ./simuleval.sh /mt/
COPY ./Dockerfile ./entrypoint.sh /mt/
RUN chmod +x /mt/entrypoint.sh
#RUN chmod +x /mt/run.sh
#RUN chmod +x /mt/simuleval.sh
WORKDIR /mt

ENTRYPOINT  /mt/entrypoint.sh $COMMAND
