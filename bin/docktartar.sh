#!/usr/bin/env bash
SECONDS=0
echo "From: ${EMAIL_FROM} <${EMAIL_FROM_ADRESS}>" | tee log.mail
echo "Subject: ${EMAIL_SUBJECT}" | tee -a log.mail
echo "[${SECONDS}] Starting Backup - $(date)" | tee -a log.mail


meid=$(cat /proc/1/cgroup | grep 'docker/' | tail -1 | sed 's/^.*\///' | cut -c 1-12)

if [  "$SMB" == "true" ]; then
    echo "[${SECONDS}] Mounting the SMB share";
    mount -t cifs -o username=${SMB_USER},passwd=${SMB_PASSWORD} //${SMB_PATH} /backupTarget
fi

running_containers=$(docker ps -q)
nof_running_containers=$(docker ps -q | wc -l)
first_to_stop="${STOP_CONTAINERS%all}"
last_to_stop="${STOP_CONTAINERS##* }"

if [ "$last_to_stop" == "all" ]; then
    echo "[${SECONDS}] Stopping $(docker stop $first_to_stop)"
    while [ $(docker ps -q | wc -l) -gt 1 ]
    do
        containers=$(docker ps -q)
        for cont in ${containers[@]}
        do
            if [[ "$cont" != "$meid" ]]
            then
                echo "[${SECONDS}] Stopping $(docker stop $cont)"
            fi
            containers=$(docker ps -q)
        done
    done
else
    echo "[${SECONDS}] Stopping $(docker stop $STOP_CONTAINERS)"
fi

echo "[${SECONDS}] Creating TAR-Archive from /backupSource"
tstamp=$(date "+%H.%M.%S-%d.%m.%y")

if [ "$TEMP_DIR" == "YES" ]; then
    echo "[${SECONDS}] Using temp directory"
    target="/backupTmp"
else
    target="/backupTarget"
fi

if [ "$INCREMENTAL" == "true" ]; then
    echo "[${SECONDS}] Doing an incremental backup"

    if [ -f /backupTarget/snap.incr ]; then
        cp "/backupTarget/snap.incr" "/backupTarget/snap.incr.bak"
    fi

    tar --listed-incremental="/backupTarget/snap.incr" -cpzf "${target}/${TAG}.${tstamp}.tar.gz" /backupSource

    if [ -f /backupTarget/snap.incr.bak ]; then
        rm "/backupTarget/snap.incr"
        mv "/backupTarget/snap.incr.bak" "/backupTarget/snap.incr"
    fi
else
    tar -c -p --use-compress-program=pigz -f "${target}/${TAG}.${tstamp}.tar.gz" /backupSource/*
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
            echo "[${SECONDS}] Restarting $(docker start $cont)"
        done
    done
else
    echo "[${SECONDS}] Restarting $(docker start $START_CONTAINERS)"
fi

if [ "$TEMP_DIR" == "YES" ]; then
    echo "The TAR-Process took $(($SECONDS_TAR / 60)) minutes and $(($SECONDS_TAR % 60)) seconds." | tee -a log.mail
    echo "[${SECONDS}] Moving to backupTarget";
    SECONDS_BAK=$SECONDS
    SECONDS=0
    mv "/backupTmp/${TAG}.${tstamp}.tar.gz" "/backupTarget/${TAG}.${tstamp}.tar.gz"
    echo "The MOVE-Process took $(($SECONDS / 60)) minutes and $(($SECONDS % 60)) seconds." | tee -a log.mail
    SECONDS=$SECONDS+SECONDS_BAK
fi

echo "[${SECONDS}] Chown the archive"
chown ${TAR_OWNER_USERID}:${TAR_OWNER_GROUPID} "/backupTarget/${TAG}.${tstamp}.tar.gz"

if [  "$SMB" == "true" ]; then
    echo "[${SECONDS}] Unmounting the SMB share"
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
