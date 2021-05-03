#
# docker build -t gdvmagent .
# docker run -e PW:<forCredFile> -e DEVICE:<deviceId> -e SECRET:<secretStringOfDevice> gdvmagent
#

FROM adoptopenjdk/openjdk11:jdk-11.0.11_9-ubuntu-slim
WORKDIR /opt
RUN apt-get update \
    && apt-get upgrade \
    && apt-get install git unzip \
    && git clone https://github.com/kyoya-p/riotProj --depth 1 \
    && cd riotProj/Trial/AgFsSnmpJvmKt \
    && sh gradlew shadowJar


FROM adoptopenjdk/openjdk11:jdk-11.0.11_9-ubuntu-slim
WORKDIR /opt
RUN apt-get update \
    && apt-get upgrade \
    && apt-get install unzip
ENV GOOGLE_APPLICATION_CREDENTIALS=/opt/road-to-iot-8efd3bfb2ccd.json
COPY --from=0 /opt/riotProj/Trial/AgFsSnmpJvmKt/road-to-iot-8efd3bfb2ccd.zip ./
COPY --from=0 /opt/riotProj/Trial/AgFsSnmpJvmKt/build/libs/AgFsSnmpJvmKt-1.0-SNAPSHOT-all.jar ./

CMD ["java","-jar","AgFsSnmpJvmKt-1.0-SNAPSHOT-all.jar"]
