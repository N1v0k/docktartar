FROM alpine:latest
MAINTAINER Gergely Mentsik "gergely@mentsik.eu"

ENV BACKUP_PERIOD=24 \
    BACKUP_DELAY=5 \
    LOOP=true \
    USERID=0 \
    GROUPID=0 \
    TAG="docker-backup" \
    STOP_CONTAINERS="all" \
    START_CONTAINERS="all" \
    TIMEZONE="Europe/Vienna"

ADD run.sh /run.sh

RUN apk add --update bash docker tar grep tzdata \
    && mkdir /backupSource \
    && mkdir /backupTarget \
    && chmod 755 /run.sh

ENTRYPOINT ["/run.sh"]