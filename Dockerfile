FROM veupathdb/vdi-plugin-handler-base:latest

RUN apk add --no-cache bash; \
  mkdir "/opt/veupathdb"

RUN apt-get update && apt-get install -y \
    python3-pip

RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir numpy && \
    pip3 install --no-cache-dir pyBigWig

COPY bin/ /opt/veupathdb/bin
COPY lib/ /opt/veupathdb/lib
COPY testdata/ /opt/veupathdb/testdata

RUN export LIB_GIT_COMMIT_SHA=fe1fc269dd66801777fba0b8d86b2ab45e9bd7ac\
    && git clone https://github.com/VEuPathDB/lib-vdi-plugin-rnaseq.git \
    && cd lib-vdi-plugin-rnaseq \
    && git checkout $LIB_GIT_COMMIT_SHA \
    && cp lib/perl/BigWigUtils.pm /opt/veupathdb/lib/perl \
    && cp bin/* /opt/veupathdb/bin

RUN chmod +x /opt/veupathdb/bin/*


