#!/bin/bash

echo "Starting up..."

cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
echo "${TIMEZONE}" >  /etc/timezone
echo "Date is: "
date

echo "Starting Backup Process"

while [ 1 ]
do
  echo "Starting Backup Process in ${BACKUP_DELAY}"
  sleep ${BACKUP_DELAY}

  echo "Starting - Stopping all containers"
  containers=$(docker ps -a -q)
  docker stop ${containers}

  echo "Creating TAR-Archive of /backupSource to /backupTarget"
  tstamp=$(date "+%H.%M.%S-%d.%m.%y")
  tar -cvpzf "/backupTarget/docker.backup.${tstamp}.tar.gz" /backupSource

  echo "Restarting all containers"
  docker start ${containers}

  echo "Chown the archive"
  chown ${TAR_OWNER_USERID}:${TAR_OWNER_GROUPID} "/backupTarget/docker.backup.${tstamp}.tar.gz"

  echo "Finished."
  [ "${LOOP}" == "true" ] || break

  echo "Next backup in ${BACKUP_PERIOD}s"
  sleep ${BACKUP_PERIOD}

done