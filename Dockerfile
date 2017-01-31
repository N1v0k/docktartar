FROM alpine:latest
MAINTAINER Gergely Mentsik "gergely@mentsik.eu"

ENV CRON="0 0 * * *" \
    USERID=0 \
    GROUPID=0 \
    TAG="docker-backup" \
    STOP_CONTAINERS="all" \
    START_CONTAINERS="all" \
    INCREMENTAL="true" \
    TIMEZONE="Europe/Vienna"

ADD bin/docktartar.sh /root/docktartar.sh
ADD bin/run.sh /root/run.sh

#RUN apt-get update && apt-get install -y bash docker tar grep tzdata cron \
RUN apk add --update bash docker tar grep tzdata cifs-utils \
    && mkdir /backupSource \
    && mkdir /backupTarget \
    && chmod 755 /root/run.sh \
    && chmod 755 /root/docktartar.sh \
    && touch /var/log/cron.log

ENTRYPOINT ["/root/run.sh"]
