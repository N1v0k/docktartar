FROM alpine:latest

ENTRYPOINT ["/run.sh"]

ENV BACKUP_PERIOD=24 \
    BACKUP_DELAY=0 \
    BACKUP_KEEPTIME=7 \
    LOOP=true \
    USERID=1001 \
    GROUPID=1001 \
    TIMEZONE="Europe/Vienna"

RUN apk add --update bash docker tar grep tzdata && \
    mkdir /backupSource && mkdir /backupTarget

ADD run.sh /run.sh
