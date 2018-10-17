#!/bin/bash
#scrypt #2_version 0.1
#
BACKUPLOG="/tmp/backup_process.log"
REMOTE_SERVER_USER="root"
REMOTE_SERVER_IP="8.8.8.8"
REMOTE_FILE_SERVER_PATH="/tmp/test_backup.log"
LOCAL_FILE_SAVE_PATH="/home/backup_log/"
LOCAL_FILE_SAVE_NAME="$(date +%d%m%y)-test_backup.log.tar.gz"
#
echo "$(date '+%Y-%m-%d %H:%M:%S') - Start backup file ${REMOTE_FILE_SERVER_PATH})" >> ${BACKUPLOG}
#Check exist file
remote_file=$(ssh -o StrictHostKeychecking=no ${REMOTE_SERVER_USER}@${REMOTE_SERVER_IP} test -f ${REMOTE_FILE_SERVER_PATH})
if [ $? -ne 0 ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR, file not exist ${REMOTE_FILE_SERVER_PATH}" >> ${BACKUPLOG} && exit 0; fi
#If file exist, clean old files in local directory
find ${LOCAL_FILE_SAVE_PATH} -type f -mtime +7 -exec rm -rf {} \;
#Compression file on remote server
ssh -o StrictHostKeychecking=no ${REMOTE_SERVER_USER}@${REMOTE_SERVER_IP} "tar -cvzf ${REMOTE_FILE_SERVER_PATH}.tar.gz ${REMOTE_FILE_SERVER_PATH}"
if [ $? -ne 0 ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR, file not compress ${REMOTE_FILE_SERVER_PATH}" >> ${BACKUPLOG} && exit 0; fi
#Copy file from remote server
rsync --verbose --archive --compress-level=9 --stats ${REMOTE_SERVER_USER}@${REMOTE_SERVER_IP}:${REMOTE_FILE_SERVER_PATH}.tar.gz ${LOCAL_FILE_SAVE_PATH}${LOCAL_FILE_SAVE_NAME}
if [ $? -ne 0 ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR, file not copy ${REMOTE_FILE_SERVER_PATH}" >> ${BACKUPLOG} && exit 0; fi
#Clean remote file
ssh -o StrictHostKeychecking=no ${REMOTE_SERVER_USER}@${REMOTE_SERVER_IP} "truncate -s 0 ${REMOTE_FILE_SERVER_PATH} & rm -rf ${REMOTE_FILE_SERVER_PATH}.tar.gz"
if [ $? -ne 0 ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR, file not cleared  ${REMOTE_FILE_SERVER_PATH}" >> ${BACKUPLOG} && exit 0; fi
echo "$(date '+%Y-%m-%d %H:%M:%S') - Success finish backup file ${REMOTE_FILE_SERVER_PATH})" >> ${BACKUPLOG}
