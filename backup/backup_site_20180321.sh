#!/bin/bash
#script_backup_some_web_site
#
BACKUPLOG="./backup.log"
SERVER_USER="user"
SERVER_IP="8.8.8.8"
FILE_SERVER_PATH="/var/www/"
FILE_SAVE_PATH="/home/user/backup/site-$(date +%Y%m%d)"
#
DATABASE_NAME="dbname"
DATABASE_USER="dbname"
DATABASE_PASS="dbpass"
#
#
#Create directory for safe files
mkdir ${FILE_SAVE_PATH}
#Dump database web site on remote server
sshpass -p $1 ssh -o StrictHostKeychecking=no ${SERVER_USER}@${SERVER_IP} "mysqldump -u'${DATABASE_USER}' ${DATABASE_NAME} -p'${DATABASE_PASS}' > dump.sql"
#Copy files web site to local server
sshpass -p $1 rsync --verbose --archive --compress-level=9 --stats ${SERVER_USER}@${SERVER_IP}:${FILE_SERVER_PATH} ${FILE_SAVE_PATH}
#Copy database to local server
sshpass -p $1 rsync --verbose --archive --compress-level=9 --stats ${SERVER_USER}@${SERVER_IP}:/home/${SERVER_USER}/dump.sql ${FILE_SAVE_PATH}
#Remove database frome remote server
sshpass -p $1 ssh -o StrictHostKeychecking=no ${SERVER_USER}@${SERVER_IP} "rm dump.sql"
#Compress web site files
tar -cvzf ${FILE_SAVE_PATH}.tar.gz ${FILE_SAVE_PATH}
#Move to another directory
mv ${FILE_SAVE_PATH}.tar.gz ./site
#Remove files
rm -rf ${FILE_SAVE_PATH}
echo "Done!"

