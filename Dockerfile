FROM alpine:3.7

WORKDIR /stamper

RUN apk update && \
  apk add --no-cache bash imagemagick pdftk

COPY stamper.sh /usr/bin/stamper.sh
RUN chmod +x /usr/bin/stamper.sh

CMD ["stamper.sh"]