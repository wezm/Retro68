# Base GCC 12 image from Debian:Bullseye
FROM gcc:12

# Branch name
ARG GIT_REPO
ARG GIT_BRANCH

# define the environment variable DEBIAN_FRONTEND=noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Update APT and install required packages
RUN apt-get clean && rm -rf /var/lib/apt/lists/* \
    && apt-get update

# Install GFortran (yeah, a pain)
RUN dpkg --purge --force-all gfortran \
    && apt-get install -y --no-install-recommends gfortran-10 \
    && update-alternatives --install /usr/bin/gfortran gfortran /usr/bin/gfortran-10 10 \
    && update-alternatives --set gfortran /usr/bin/gfortran-10 

# Install other languages and development libraries
# note: in the gcc image, git is already installed, as well as make, gcc, g++, etc.

RUN apt-get install --no-install-recommends -y bzip2 perl ruby cmake libcoarrays-dev libcoarrays-openmpi-dev libmpfr-dev libmpc-dev zlib1g-dev libboost-all-dev bison texinfo flex
    #&& rm -rf /var/lib/apt/lists/* 
    #&& mkdir /opt/Retro68

# Either copy the code of the Retro68 repo from the host into the container
COPY . /opt/Retro68

# Or, clone the repo 
#RUN cd /opt && git clone --recurse-submodules -b $GIT_BRANCH https://github.com/$GIT_REPO

# /!\ In this case, you should download and extract the InterfacesAndLibraries files from wherever you uploaded it
#     and copy it to the container under /opt/Retro68/InterfacesAndLibraries
# COPY ./InterfacesAndLibraries /opt/Retro68/InterfacesAndLibraries

# Build Retro68 toolchain (this takes a LONG time)
RUN mkdir /opt/Retro68/build && cd /opt/Retro68/build \
    && export PATH=/opt/Retro68/build/toolchain/bin:$PATH \
    && ../build-toolchain.bash --universal --no-68k --no-carbon 

# Downloads and extract Executor2000 (for performing basic tests) from the author's repo
RUN cd /opt/ \
    && curl -L -O https://github.com/autc04/executor/releases/download/v0.1.0/Executor2000-0.1.0-Linux.tar.bz2 \
    && tar xfvj ./Executor2000-0.1.0-Linux.tar.bz2 Executor2000-0.1.0-Linux/bin/executor-headless \
    && rm -f ./Executor2000-0.1.0-Linux.tar.bz2 \
    && chmod +x /opt/Executor2000-0.1.0-Linux/bin/executor-headless \
    && echo "executor-path=/opt/Executor2000-0.1.0-Linux/bin/executor-headless" > ~/.LaunchAPPL.cfg \
    && echo "emulator=executor" >> ~/.LaunchAPPL.cfg

# # On start, run the tests with executor and wait in loop
ENTRYPOINT ["/bin/bash", "-c", "cd /opt/Retro68/build && ctest --no-compress-output --verbose -T test -E Carbon --output-junit /tmp/Retro68-tests.xml && while true; do sleep 5; done;"]
