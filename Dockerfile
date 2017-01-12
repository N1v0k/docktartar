FROM alpine:latest
MAINTAINER Gergely Mentsik "gergely@mentsik.eu"

ENV BACKUP_PREDELAY=12h \
    BACKUP_POSTDELAY=12h \
    LOOP=true \
    USERID=0 \
    GROUPID=0 \
    TAG="docker-backup" \
    STOP_CONTAINERS="all" \
    START_CONTAINERS="all" \
    INCREMENTAL="true" \
    TIMEZONE="Europe/Vienna"

ADD bin/docktartar.sh /docktartar.sh
ADD bin/run.sh /run.sh

RUN apk add --no-cache --update bash docker tar grep tzdata cron \
    && mkdir /backupSource \
    && mkdir /backupTarget \
    && chmod 755 /run.sh \
    && chmod 755 /docktartar.sh \
    && touch /var/log/cron.log

CMD ["/run.sh" && cron && tail -f /var/log/cron.log]