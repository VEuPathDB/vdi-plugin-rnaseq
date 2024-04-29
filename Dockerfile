FROM veupathdb/vdi-plugin-base:6.0.1

RUN apt-get update \
    && apt-get install -y python3-numpy python3-pybigwig \
    && apt-get clean

COPY bin/ /opt/veupathdb/bin
COPY lib/ /opt/veupathdb/lib
#COPY testdata/ /opt/veupathdb/testdata

RUN export LIB_GIT_COMMIT_SHA=099844ec5005e7fab95358b2b538dbe4f0581572\
    && git clone https://github.com/VEuPathDB/vdi-lib-plugin-rnaseq.git \
    && cd vdi-lib-plugin-rnaseq \
    && git checkout $LIB_GIT_COMMIT_SHA \
    && cp lib/perl/BigWigUtils.pm /opt/veupathdb/lib/perl \
    && cp bin/* /opt/veupathdb/bin

RUN chmod +x /opt/veupathdb/bin/*


