FROM veupathdb/vdi-plugin-base:8.1.2

ENV ORACLE_HOME=/opt/oracle \
  LD_LIBRARY_PATH=/opt/oracle


RUN apt-get update \
  && apt-get install -y git perl libaio1t64 libdbi-perl unzip python3 \
    python3-numpy python3-pybigwig libtest-nowarnings-perl make gcc \
  && apt-get clean \
  && ln -s /usr/lib/x86_64-linux-gnu/libaio.so.1t64 /usr/lib/x86_64-linux-gnu/libaio.so.1


# ORACLE INSTANT CLIENT
RUN mkdir -p ${ORACLE_HOME} \
  && cd ${ORACLE_HOME} \
  && wget -q https://download.oracle.com/otn_software/linux/instantclient/2370000/instantclient-basic-linux.x64-23.7.0.25.01.zip -O instant.zip \
  && wget -q https://download.oracle.com/otn_software/linux/instantclient/2370000/instantclient-sqlplus-linux.x64-23.7.0.25.01.zip -O sqlplus.zip \
  && wget -q https://download.oracle.com/otn_software/linux/instantclient/2370000/instantclient-sdk-linux.x64-23.7.0.25.01.zip -O sdk.zip \
  && wget -q https://download.oracle.com/otn_software/linux/instantclient/2370000/instantclient-tools-linux.x64-23.7.0.25.01.zip -O tools.zip \
  && unzip -o instant.zip \
  && unzip -o sqlplus.zip \
  && unzip -o sdk.zip \
  && unzip -o tools.zip \
  && rm instant.zip sdk.zip sqlplus.zip tools.zip \
  && mv instantclient_23_7/* . \
  && rm -rf instantclient_23_7 \
  && mv -t /usr/bin/ sqlplus sqlldr \
  \
  && cpan ZARQUON/DBD-Oracle-1.83.tar.gz


# DBI UTILS
ARG LIB_DBI_UTILS_VERSION=1.0.0
RUN mkdir -p /opt/veupathdb/lib \
  && cd /opt/veupathdb/lib \
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
