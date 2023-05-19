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

RUN export LIB_GIT_COMMIT_SHA=3900580bd250ea79ee8f9d3e4512b4591c7dff35\
    && git clone https://github.com/VEuPathDB/lib-vdi-plugin-rnaseq.git \
    && cd lib-vdi-plugin-rnaseq \
    && git checkout $LIB_GIT_COMMIT_SHA \
    && cp bin/* /opt/veupathdb/bin 

RUN chmod +x /opt/veupathdb/bin/*


