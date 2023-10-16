FROM veupathdb/vdi-plugin-base:1.0.22

RUN apt-get update && apt-get install -y \
    python3-pip

RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir numpy && \
    pip3 install --no-cache-dir pyBigWig

COPY bin/ /opt/veupathdb/bin
COPY lib/ /opt/veupathdb/lib
#COPY testdata/ /opt/veupathdb/testdata

RUN export LIB_GIT_COMMIT_SHA=435acc522fdf44ec6d5171165db2b71079693100\
    && git clone https://github.com/VEuPathDB/vdi-lib-plugin-rnaseq.git \
    && cd vdi-lib-plugin-rnaseq \
    && git checkout $LIB_GIT_COMMIT_SHA \
    && cp lib/perl/BigWigUtils.pm /opt/veupathdb/lib/perl \
    && cp bin/* /opt/veupathdb/bin

RUN chmod +x /opt/veupathdb/bin/*


