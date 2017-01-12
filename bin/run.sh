#!/usr/bin/env bash

echo "Version: ${VERSION}"
echo "Registering new cron..."
echo "* * * * * root echo \"Hello world\" >> /var/log/cron.log 2>&1 \n" >> /etc/cron.d/docktartar
chmod 0644 etc/cron.d/docktartar
echo "OK - waiting for job to execute."