FROM phusion/baseimage:latest

ENV HOME /root
ENV ANDROID_HOME /android/sdk
ENV NDK_ROOT /android/ndk32-toolchains

WORKDIR /tmp

CMD ["/sbin/my_init"]

# install dependencies
RUN \
    echo debconf debconf/frontend select Noninteractive | debconf-set-selections && \
    echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
    echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections && \
    dpkg --add-architecture i386 && \
    add-apt-repository ppa:webupd8team/java && \
    apt-get update && \
    apt-get install -y \
        ant \
        git \
        libegl1-mesa-dev \
        libgles2-mesa-dev \
        libncurses5:i386 \
        libstdc++6:i386 \
        mercurial \
        oracle-java8-installer \
        oracle-java8-set-default \
        unzip \
        xdotool \
        zlib1g:i386

# install Android SDK
ENV ANDROID_SDK_REV r23.0.2
RUN mkdir /android

RUN wget https://dl.google.com/android/adt/adt-bundle-linux-x86_64-20140702.zip
RUN unzip /tmp/adt-bundle-linux-x86_64-20140702.zip
RUN mv adt-bundle-linux-x86_64-20140702/sdk /android/

# you may be using standalone sdk instead of adt bundle.
#RUN wget http://dl.google.com/android/android-sdk_$ANDROID_SDK_REV-linux.tgz
#RUN tar zxf android-sdk_$ANDROID_SDK_REV-linux.tgz
#RUN mv android-sdk-linux /android/sdk

RUN (sleep 5; while [ 1 ]; do sleep 1; echo y; done ) | /android/sdk/tools/android update sdk --no-ui --filter platform,tool,platform-tool

# install Android NDK
ENV ANDROID_NDK_REV r10b
RUN wget http://dl.google.com/android/ndk/android-ndk32-$ANDROID_NDK_REV-linux-x86_64.tar.bz2
RUN tar jxf android-ndk32-$ANDROID_NDK_REV-linux-x86_64.tar.bz2
RUN mv android-ndk-r10b /android/ndk32

# setup NDK
RUN /bin/bash /android/ndk32/build/tools/make-standalone-toolchain.sh --platform=android-9 --install-dir=/android/ndk32-toolchains --system=linux-x86_64
RUN echo 'export NDK_ROOT=/android/ndk32-toolchains' >> $HOME/.bashrc

# clone goandroid
ENV GOANDROID_DIR $HOME/goandroid
RUN git clone https://github.com/eliasnaur/goandroid.git $GOANDROID_DIR

# setup Go 1.2.2 for goandroid
ENV GODIR $GOANDROID_DIR/go
RUN hg clone -u go1.2.2 https://code.google.com/p/go $GODIR
RUN cp -a $GOANDROID_DIR/patches $GODIR/.hg
RUN echo '[extensions]' >> $GODIR/.hg/hgrc
RUN echo 'mq = ' >> $GODIR/.hg/hgrc
RUN echo 'codereview = !' >> $GODIR/.hg/hgrc
RUN echo '[ui]' >> $GODIR/.hg/hgrc
RUN echo 'username = Takashi Oguma<bear.mini@gmail.com>' >> $GODIR/.hg/hgrc
RUN cd $GODIR/src && hg qpush -a && CGO_ENABLED=0 GOOS=linux GOARCH=arm ./make.bash CC="$NDK_ROOT/bin/arm-linux-androideabi-gcc" GOOS=linux GOARCH=arm GOARM=7 CGO_ENABLED=1
RUN echo 'export ANDROID_HOME=/android/sdk' >> $HOME/.bashrc
RUN cd $GOANDROID_DIR/hello-gl2 && ./build.sh && ant -f android/build.xml clean debug
RUN cd $GOANDROID_DIR/native-activity && ./build.sh && ant -f android/build.xml clean debug

RUN echo 'export HOME=/root' >> $HOME/.bashrc

# clean up
#RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

