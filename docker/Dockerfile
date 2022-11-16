#FROM ubuntu:16.04
FROM ubuntu:20.04

ENV TZ=Europe/Spain
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ARG DEBIAN_FRONTEND=noninteractive

ARG USERNAME
ARG GROUPNAME
ARG USERID
ARG GROUPID

RUN apt-get update && apt-get install -y \
	sudo \
	wget \
	gcc \
	make \
	g++ \
	bison \
	flex \
	gettext \
	texinfo \
	patch bzip2 cpio python unzip \
	git \
	u-boot-tools\
	fakeroot \
	gawk \
	busybox \
	lzma \
	libc6-dev-i386 \ 
	lib32stdc++6 \
	zlib1g-dev \
	lib32ncurses5-dev \
	gcc-multilib \
	lib32z1 \
	dos2unix \
	m4 \
	automake \
	curl \	
	cmake \
    autoconf \
    libtool \
    libtool-bin \
    pkg-config \
    vim \
    rsync \
    libarchive-tools \
    zip \
    nano \
    tzdata \
    libnl-genl-3-dev \
    python3-pip \
	&& apt-get clean \
	&& rm -fR /var/lib/apt/lists/*

# Base builder with machine user
ARG USERNAME
ARG GROUPNAME
ARG USERID
ARG GROUPID
RUN echo $GROUPID
RUN echo $GROUPNAME
RUN groupadd -g $GROUPID $GROUPNAME && \
    useradd -m -r -u $USERID -g $GROUPNAME $USERNAME

# Builder with depot tools used for building 
ARG USERNAME
USER $USERNAME
WORKDIR /home/$USERNAME
RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git .depot_tools
ENV PATH="/home/$USERNAME/.depot_tools:${PATH}"

USER root
ARG USERNAME

RUN dpkg --add-architecture i386 

ENV GOSU_VERSION=1.10

RUN dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
	&& wget -q -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
	&& chmod +sx /usr/local/bin/gosu

RUN cd /root && git clone https://github.com/Distrotech/flux && cd flux && \
  autoreconf -fi  && ./configure --host=arm-linux-gnueabihf && make && make install 

VOLUME ["/rbn"]

WORKDIR /rbn

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh 
RUN chmod +s /usr/local/bin/gosu

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/bin/bash"]
 
ENV USER_NAME=$USERNAME

WORKDIR /rbn

