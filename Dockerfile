FROM veupathdb/vdi-plugin-handler-base:latest

RUN apk add --no-cache bash; \
  mkdir "/opt/veupathdb"

COPY bin/ /opt/veupathdb/bin
COPY lib/ /opt/veupathdb/lib
COPY testdata/ /opt/veupathdb/testdata

RUN chmod +x /opt/veupathdb/bin/*