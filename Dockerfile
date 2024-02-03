FROM veupathdb/vdi-plugin-base:3.2.0

RUN apt-get update \
    && apt-get install -y python3-numpy python3-pybigwig \
    && apt-get clean

COPY bin/ /opt/veupathdb/bin
COPY lib/ /opt/veupathdb/lib
#COPY testdata/ /opt/veupathdb/testdata

RUN export LIB_GIT_COMMIT_SHA=e8f38a9c282cf73f03b6a7964ee813fe180c78ce\
    && git clone https://github.com/VEuPathDB/vdi-lib-plugin-rnaseq.git \
    && cd vdi-lib-plugin-rnaseq \
    && git checkout $LIB_GIT_COMMIT_SHA \
    && cp lib/perl/BigWigUtils.pm /opt/veupathdb/lib/perl \
    && cp bin/* /opt/veupathdb/bin

RUN chmod +x /opt/veupathdb/bin/*


