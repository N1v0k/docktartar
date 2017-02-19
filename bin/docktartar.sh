#!/usr/bin/env bash

echo "Starting Backup - $(date)" | tee log.mail
SECONDS=0

meid=$(cat /proc/1/cgroup | grep 'docker/' | tail -1 | sed 's/^.*\///' | cut -c 1-12)

if [  "$SMB" == "true" ]; then
    echo "Mounting the SMB share";
    mount -t cifs -o username=${SMB_USER},passwd=${SMB_PASSWORD} //${SMB_PATH} /backupTarget
fi

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
    echo "Doing an incremental backup"

    if [ -f /backupTarget/snap.incr ]; then
        cp "/backupTarget/snap.incr" "/backupTarget/snap.incr.bak"
    fi

    tar --listed-incremental="/backupTarget/snap.incr" -cpzf "/backupTarget/${TAG}.${tstamp}.tar.gz" /backupSource

    if [ -f /backupTarget/snap.incr.bak ]; then
        rm "/backupTarget/snap.incr"
        mv "/backupTarget/snap.incr.bak" "/backupTarget/snap.incr"
    fi

else
    tar -c -p --use-compress-program=pigz -f "/backupTarget/${TAG}.${tstamp}.tar.gz" /backupSource/*
    tar_result=$?
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

if [  "$SMB" == "true" ]; then
    echo "Unmounting the SMB share"
    umount /backupTarget
fi

size=$(ls -sh "/backupTarget/${TAG}.${tstamp}.tar.gz")
echo "Archive size: $size" | tee -a log.mail

duration=$SECONDS
echo "Backup $TAG took $(($duration / 60)) minutes and $(($duration % 60)) seconds." | tee -a log.mail

if [[ $tar_result != 0 ]]; then
    echo "Attention, the tar-process returned a non-zero exit code: $tar_result" | tee -a log.mail
fi

if [ -n "$EMAIL_TO" ];then
    echo "Sending email to ${EMAIL_TO}"
    ssmtp ${EMAIL_TO} < log.mail
fi

echo "Finished."
