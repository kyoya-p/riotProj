FROM adoptopenjdk/openjdk11
WORKDIR /opt
RUN apt update \
    && apt upgrade \
    && apt install -y git \
    && git clone https://github.com/kyoya-p/riotProj --depth 1 \
    && cd riotProj\Trial\AgFsSnmpJvmKt \
    && sh gradlew build


