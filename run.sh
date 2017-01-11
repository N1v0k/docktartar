#!/bin/bash

VERSION="[v0.9] [06.01.2017]"

cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
echo "${TIMEZONE}" >  /etc/timezone

echo "Version: ${VERSION}"

while [ 1 ]
do
    echo "Starting - $(date), waiting for ${BACKUP_PREDELAY}"
    sleep ${BACKUP_PREDELAY}

    meid=$(cat /proc/1/cgroup | grep 'docker/' | tail -1 | sed 's/^.*\///' | cut -c 1-12)

    running_containers=$(docker ps -q)
    nof_running_containers=$(docker ps -q | wc -l)
    first_to_stop="${STOP_CONTAINERS%all}"
    last_to_stop="${STOP_CONTAINERS##* }"

    if [ "$last_to_stop" == "all" ]; then
        echo "Stopping $(docker stop $first_to_stop)"
        while [ $(docker ps -q | wc -l) -gt 1 ]
        do
            containers=$(docker ps -q)
            for cont in ${containers[@]}
            do
                if [[ "$cont" != "$meid" ]]
                then
                    echo "Stopping $(docker stop $cont)"
                fi
                containers=$(docker ps -q)
            done
        done
    else
        echo "Stopping $(docker stop $STOP_CONTAINERS)"
    fi


    echo "Creating TAR-Archive of /backupSource to /backupTarget"
    tstamp=$(date "+%H.%M.%S-%d.%m.%y")

    if [ "$INCREMENTAL" == "true" ]; then
        tar --listed-incremental=snap.incr -cvpzf "/backupTarget/${TAG}.${tstamp}.tar.gz" /backupSource
    else
        tar -cvpzf "/backupTarget/${TAG}.${tstamp}.tar.gz" /backupSource
    fi
    first_to_start="${START_CONTAINERS%all}"
    last_to_start="${START_CONTAINERS##* }"

    if [ "$last_to_start" == "all" ]; then
        echo "Restarting $(docker start $first_to_start)"
        while [ $nof_running_containers -ne $(docker ps -q | wc -l) ]
        do
            for cont in ${running_containers[@]}
            do
                echo "Restarting $(docker start $cont)"
            done
        done
    else
        echo "Restarting $(docker start $START_CONTAINERS)"
    fi

  echo "Chown the archive"
  chown ${TAR_OWNER_USERID}:${TAR_OWNER_GROUPID} "/backupTarget/${TAG}.${tstamp}.tar.gz"

  echo "Finished."
  [ "${LOOP}" == "true" ] || break

  echo "Waiting for ${BACKUP_POSTDELAY}"
  sleep ${BACKUP_POSTDELAY}

done