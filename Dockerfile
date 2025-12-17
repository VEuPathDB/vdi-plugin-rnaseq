FROM amazoncorretto:25-alpine3.22-jdk

ENV LANG=en_US.UTF-8 \
  JVM_MEM_ARGS="-Xms16m -Xmx64m" \
  JVM_ARGS="" \
  TZ="America/New_York" \
  PATH=/opt/veupathdb/bin:$PATH

RUN apk add --no-cache \
     wget git tzdata unzip make gcc netcat-openbsd musl-dev \
     curl libcurl curl-dev  \
     perl perl-dbi perl-test-nowarnings perl-dbd-pg \
     python3 python3-dev py3-pip py3-numpy \
  && cp /usr/share/zoneinfo/America/New_York /etc/localtime \
  && echo ${TZ} > /etc/timezone \
  && pip install --break-system-packages pybigwig

# DBI UTILS
ARG LIB_DBI_UTILS_VERSION=1.0.0
RUN mkdir -p /opt/veupathdb/lib/perl \
  && cd /opt/veupathdb/lib/perl \
  && wget -q https://github.com/VEuPathDB/lib-perl-dbi-utils/releases/download/v${LIB_DBI_UTILS_VERSION}/dbi-utils-v${LIB_DBI_UTILS_VERSION}.zip -O utils.zip \
  && unzip utils.zip \
  && rm utils.zip

ARG LIB_GIT_COMMIT_SHA=099844ec5005e7fab95358b2b538dbe4f0581572
RUN git clone https://github.com/VEuPathDB/vdi-lib-plugin-rnaseq.git \
  && cd vdi-lib-plugin-rnaseq \
  && git checkout ${LIB_GIT_COMMIT_SHA} \
  && mkdir -p /opt/veupathdb/lib/perl /opt/veupathdb/bin \
  && cp lib/perl/BigWigUtils.pm /opt/veupathdb/lib/perl \
  && cp bin/* /opt/veupathdb/bin \
  && rm -rf lib-vdi-plugin-rnaseq

COPY bin/ /opt/veupathdb/bin
COPY lib/ /opt/veupathdb/lib

RUN chmod +x /opt/veupathdb/bin/*

# VDI PLUGIN SERVER
ARG PLUGIN_SERVER_VERSION=v1.7.0-a26
RUN curl "https://github.com/VEuPathDB/vdi-service/releases/download/${PLUGIN_SERVER_VERSION}/plugin-server.tar.gz" -Lf --no-progress-meter | tar -xz

CMD PLUGIN_ID=rnaseq /startup.sh
