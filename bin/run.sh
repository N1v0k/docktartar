#!/usr/bin/env bash
VERSION="[v0.9.1] [12.01.2017]"

echo "Version: ${VERSION}"

cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
echo "${TIMEZONE}" >  /etc/timezone

echo "Registering new cron..."
echo "${CRON} root echo \"Hello world\" >> /var/log/cron.log 2>&1 \n" >> /etc/cron.d/docktartar
chmod 0644 etc/cron.d/docktartar

echo "OK - waiting for job to execute."
cron && tail -f /var/log/cron.log
