FROM phusion/baseimage:latest

CMD ["/sbin/my_init"]
WORKDIR /tmp

ENV HOME /root
ENV ANDROID_HOME /android/sdk
ENV ANDROID_SDK_REV r23.0.2
ENV ANDROID_NDK_REV r10b
ENV NDK_ROOT /android/ndk32-toolchains
ENV GOANDROID_DIR $HOME/goandroid
ENV GOROOT $GOANDROID_DIR/go
ENV GOPATH $HOME/gopath

RUN echo 'export HOME=/root' >> $HOME/.bashrc
RUN echo 'export ANDROID_HOME=/android/sdk' >> $HOME/.bashrc
RUN echo 'export NDK_ROOT=/android/ndk32-toolchains' >> $HOME/.bashrc
RUN echo 'export GOANDROID_DIR=/root/goandroid' >> $HOME/.bashrc
RUN echo 'export GOANDROID=/root/goandroid/go/bin' >> $HOME/.bashrc
RUN echo 'export GOROOT=$GOANDROID_DIR/go' >> $HOME/.bashrc
RUN echo 'export GOPATH=/root/gopath' >> $HOME/.bashrc
RUN echo 'export PATH=$PATH:/android/sdk/platform-tools:/android/sdk/build-tools:/android/sdk/tools:$GOROOT/bin:$GOPATH/bin' >> $HOME/.bashrc

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
        cmake \
        git \
        libegl1-mesa-dev \
        libgles2-mesa-dev \
        libglu1-mesa-dev \
        libncurses5:i386 \
        libstdc++6:i386 \
        mercurial \
        oracle-java8-installer \
        oracle-java8-set-default \
        unzip \
        xdotool \
        xorg-dev \
        zlib1g:i386

###
# install Android SDK
RUN mkdir /android

# install ADT-bundle (you can choose either ADT-bundle or standalone SDK)
#RUN wget -q https://dl.google.com/android/adt/adt-bundle-linux-x86_64-20140702.zip
#RUN unzip /tmp/adt-bundle-linux-x86_64-20140702.zip
#RUN mv adt-bundle-linux-x86_64-20140702/sdk /android/

# install standalone SDK (you can choose either ADT-bundle or standalone SDK)
RUN wget -q http://dl.google.com/android/android-sdk_$ANDROID_SDK_REV-linux.tgz
RUN tar zxf android-sdk_$ANDROID_SDK_REV-linux.tgz
RUN mv android-sdk-linux /android/sdk

RUN (sleep 5; while [ 1 ]; do sleep 1; echo y; done ) | /android/sdk/tools/android update sdk --no-ui --filter android-20,android-19,build-tools-20.0.0,platform-tools

###
# install Android NDK
RUN wget -q http://dl.google.com/android/ndk/android-ndk32-$ANDROID_NDK_REV-linux-x86_64.tar.bz2
RUN tar jxf android-ndk32-$ANDROID_NDK_REV-linux-x86_64.tar.bz2
RUN mv android-ndk-$ANDROID_NDK_REV /android/ndk32

# setup NDK
RUN /bin/bash /android/ndk32/build/tools/make-standalone-toolchain.sh --platform=android-9 --install-dir=/android/ndk32-toolchains --system=linux-x86_64

###
# install goandroid and setup Go 1.2.2 for goandroid
RUN git clone https://github.com/eliasnaur/goandroid.git $GOANDROID_DIR
RUN hg clone -u go1.2.2 https://code.google.com/p/go $GOROOT
RUN cp -a $GOANDROID_DIR/patches $GOROOT/.hg
RUN echo '[extensions]' >> $GOROOT/.hg/hgrc
RUN echo 'mq = ' >> $GOROOT/.hg/hgrc
RUN echo 'codereview = !' >> $GOROOT/.hg/hgrc
RUN echo '[ui]' >> $GOROOT/.hg/hgrc
RUN echo 'username = Takashi Oguma<bear.mini@gmail.com>' >> $GOROOT/.hg/hgrc
RUN cd $GOROOT/src && hg qpush -a && CGO_ENABLED=0 GOOS=linux GOARCH=arm ./make.bash CC="$NDK_ROOT/bin/arm-linux-androideabi-gcc" GOOS=linux GOARCH=arm GOARM=7 CGO_ENABLED=1
#RUN cd $GOANDROID_DIR/hello-gl2 && ./build.sh && ant -f android/build.xml clean debug
#RUN cd $GOANDROID_DIR/native-activity && ./build.sh && ant -f android/build.xml clean debug

###
# setup GLFW3
RUN mkdir $GOPATH
RUN $GOROOT/bin/go get github.com/remogatto/egl
RUN GOPATH=$GOPATH $GOROOT/bin/go get github.com/remogatto/opengles2 || true    # ignoring build error on installation
RUN GOPATH=$GOPATH $GOROOT/bin/go get github.com/bearmini/opengles2
RUN ln -s $GOPATH/src/github.com/bearmini/opengles2 $GOPATH/src/github.com/remogatto/opengles2
RUN git clone https://github.com/glfw/glfw.git $HOME/glfw && cd $HOME/glfw && mkdir build
RUN cd $HOME/glfw/build && cmake -DBUILD_SHARED_LIBS=on .. && make && make install
RUN GOPATH=$GOPATH $GOROOT/bin/go get github.com/go-gl/glfw3

###
# setup mandala
RUN GOPATH=$GOPATH $GOROOT/bin/go get github.com/jingweno/gotask
#RUN GOPATH=$GOPATH $GOROOT/bin/go get github.com/remogatto/mandala
RUN GOPATH=$GOPATH $GOROOT/bin/go get github.com/bearmini/mandala
RUN ln -s $GOPATH/src/github.com/bearmini/mandala $GOPATH/src/github.com/remogatto/mandala
RUN GOPATH=$GOPATH $GOROOT/bin/go get github.com/remogatto/mandala-template
RUN cd $GOPATH/src && $GOPATH/bin/mandala-template myapp && cd myapp && PATH=$PATH:$GOROOT/bin $GOPATH/bin/gotask init
RUN cd $GOPATH && git clone https://github.com/remogatto/mandala-examples


###
# clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

