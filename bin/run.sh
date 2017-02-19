#!/usr/bin/env bash
VERSION="[v1.0.4] [18.02.2017]"

echo "Version: ${VERSION}"

cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
echo "${TIMEZONE}" >  /etc/timezone

echo "Registering new cron..."
echo "${CRON} /root/docktartar.sh >> /var/log/cron.log 2>&1 \n" >> /root/docktartar.cron
crontab /root/docktartar.cron

echo "Setting up mail..."

if [ -n "$EMAIL_ADRESS" ];then
    echo "root=${EMAIL_ADRESS}" > /etc/ssmtp/ssmtp.conf
    echo "mailhub=${EMAIL_HOST_PORT}" >> /etc/ssmtp/ssmtp.conf
    echo "AuthUser=${EMAIL_USER}" >> /etc/ssmtp/ssmtp.conf
    echo "AuthPass=${EMAIL_PASS}" >> /etc/ssmtp/ssmtp.conf
    echo "UseSTARTTLS=${EMAIL_USE_STARTTLS}" >> /etc/ssmtp/ssmtp.conf
    echo "FromLineOverride=${EMAIL_FROM}" >> /etc/ssmtp/ssmtp.conf
    echo "hostname=${EMAIL_HOSTNAME}" >> /etc/ssmtp/ssmtp.conf
fi


echo "OK - waiting for job to execute."
/usr/sbin/crond && tail -f /var/log/cron.log
