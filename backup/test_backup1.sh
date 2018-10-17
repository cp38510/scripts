#!/bin/bash
#scrypt #1_version 0.1
#
BACKUPLOG="/tmp/create_file_process.log"
FILE_SERVER_PATH="/tmp/test_backup.log"
#
echo "$(date '+%Y-%m-%d %H:%M:%S') - Start create file ${FILE_SERVER_PATH}" >> ${BACKUPLOG}
head -c 100000000 < /dev/urandom > ${FILE_SERVER_PATH}
if [ $? -ne 0 ];
then
echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR create file ${FILE_SERVER_PATH}" >> ${BACKUPLOG}
else
echo "$(date '+%Y-%m-%d %H:%M:%S') - Success finish create file ${FILE_SERVER_PATH}" >> ${BACKUPLOG}
fi
