FROM veupathdb/vdi-plugin-handler-base:latest

RUN apk add --no-cache bash; \
  mkdir "/opt/veupathdb"

COPY bin/ /opt/veupathdb/bin
COPY lib/ /opt/veupathdb/lib
COPY testdata/ /opt/veupathdb/testdata

RUN export LIB_GIT_COMMIT_SHA=2e80763b6752eb6ee3b0e9de60c0ee05b8b88fc7\
    && git clone https://github.com/VEuPathDB/lib-vdi-plugin-rnaseq.git \
    && cd lib-vdi-handler-rnaseq \
    && git checkout $LIB_GIT_COMMIT_SHA \
    && cp bin/* /opt/veupathdb/bin 

RUN chmod +x /opt/veupathdb/bin/*
