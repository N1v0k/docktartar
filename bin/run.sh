#!/usr/bin/env bash
VERSION="[v1.0.1] [13.01.2017]"

echo "Version: ${VERSION}"

cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
echo "${TIMEZONE}" >  /etc/timezone

echo "Registering new cron..."
echo "${CRON} /root/docktartar.sh >> /var/log/cron.log 2>&1 \n" >> /root/docktartar.cron
crontab /root/docktartar.cron

echo "OK - waiting for job to execute."
/usr/sbin/crond && tail -f /var/log/cron.log
