#!/usr/bin/env bash
VERSION="[v0.9.1] [12.01.2017]"

echo "Version: ${VERSION}"

cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
echo "${TIMEZONE}" >  /etc/timezone

echo "Registering new cron..."
echo "${CRON} echo \"Hello world\" >> /var/log/cron.log 2>&1 \n" >> /root/docktartar.cron
crontab /root/docktartar.cron

echo "OK - waiting for job to execute."
/usr/sbin/crond && tail -f /var/log/cron.log
