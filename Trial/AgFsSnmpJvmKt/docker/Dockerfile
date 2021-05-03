FROM adoptopenjdk/openjdk11
WORKDIR /opt
RUN apt update \
    && apt-get upgrade \
    && apt-get install git unzip \
    && git clone https://github.com/kyoya-p/riotProj --depth 1 \
    && cd riotProj/Trial/AgFsSnmpJvmKt \
    && sh gradlew shadowJar
ENV GOOGLE_APPLICATION_CREDENTIALS=road-to-iot-8efd3bfb2ccd.json

