#!/usr/bin/env bash
SECONDS=0

if [ -n "$EMAIL_TO" ];then
    echo "From: ${EMAIL_FROM} <${EMAIL_FROM_ADRESS}>" | tee log.mail
    echo "Subject: ${EMAIL_SUBJECT}" | tee -a log.mail
fi
echo "Starting Backup - $(date) ." | tee -a log.mail

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

echo "Looking for sockets to exclude them from the archive..."
cd /backupSource && find . -type s > /root/socketlist
cd /

echo "Creating TAR-Archive from /backupSource"
tstamp=$(date "+%H.%M.%S-%d.%m.%y")

if [ "$TEMP_DIR" == "YES" ]; then
    echo "Using temp directory"
    target="/backupTmp"
else
    target="/backupTarget"
fi

if [ "$INCREMENTAL" == "true" ]; then
    echo "Doing an incremental backup"

    if [ -f /backupTarget/snap.incr ]; then
        cp "/backupTarget/snap.incr" "/backupTarget/snap.incr.bak"
    fi

    tar --listed-incremental="/backupTarget/snap.incr" --exclude-from=/root/socketlist -c -p --use-compress-program=pigz --exclude-from=/root/socketlist -f "${target}/${TAG}.${tstamp}.tar.gz" -C /backupSource .

    if [ -f /backupTarget/snap.incr.bak ]; then
        rm "/backupTarget/snap.incr"
        mv "/backupTarget/snap.incr.bak" "/backupTarget/snap.incr"
    fi
else
    tar -c -p --use-compress-program=pigz --exclude-from=/root/socketlist -f "${target}/${TAG}.${tstamp}.tar.gz" -C /backupSource .
    tar_result=$?
fi

SECONDS_TAR=$SECONDS

first_to_start="${START_CONTAINERS%all}"
last_to_start="${START_CONTAINERS##* }"

if [ "$last_to_start" == "all" ]; then
    echo "[${SECONDS}] Restarting $(docker start $first_to_start)"
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

if [ "$TEMP_DIR" == "YES" ]; then
    echo "The TAR-Process took $(($SECONDS_TAR / 60)) minutes and $(($SECONDS_TAR % 60)) seconds." | tee -a log.mail
    echo "Moving to backupTarget";
    SECONDS_BAK=$SECONDS
    SECONDS=0
    mv "/backupTmp/${TAG}.${tstamp}.tar.gz" "/backupTarget/${TAG}.${tstamp}.tar.gz"
    echo "The MOVE-Process took $(($SECONDS / 60)) minutes and $(($SECONDS % 60)) seconds." | tee -a log.mail
    SECONDS=$(($SECONDS+$SECONDS_BAK))
fi

echo "Chown the archive"
chown ${TAR_OWNER_USERID}:${TAR_OWNER_GROUPID} "/backupTarget/${TAG}.${tstamp}.tar.gz"

if [  "$SMB" == "true" ]; then
    echo "Unmounting the SMB share"
    umount /backupTarget
fi

size=$(du -h "/backupTarget/${TAG}.${tstamp}.tar.gz" | cut -f1)
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
