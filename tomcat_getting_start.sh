#!/bin/bash
#dz2_tomcat_version 0.1
#
SCRIPT_LOG_PATH="/tmp/deploy_process.log"
GIT_PATH="https://github.com/mnryerasi/java_Test.git"
DIRECTORY_FOR_CLONE_GIT="/tmp/git"
REMOTE_SERVER_USER="root"
REMOTE_SERVER_IP="8.8.8.8"
REMOTE_FILE_SERVER_PATH="/var/lib/tomcat8/webapps/"
#
echo "$(date '+%Y-%m-%d %H:%M:%S') - Start deploy project ${GIT_PATH}" >> ${SCRIPT_LOG_PATH}
#Remove old directory, if it exist
rm -rf ${DIRECTORY_FOR_CLONE_GIT}
#Clone git repository
git clone ${GIT_PATH} ${DIRECTORY_FOR_CLONE_GIT}
if [ $? -ne 0 ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR, project don't clone from git" >> ${SCRIPT_LOG_PATH} && exit 0; fi
#Collect application
mvn package -f ${DIRECTORY_FOR_CLONE_GIT}
if [ $? -ne 0 ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR, project don't collect in Maven" >> ${SCRIPT_LOG_PATH} && exit 0; fi
#Remove old directory, if it exist
TMP_VAR=$(ls ${DIRECTORY_FOR_CLONE_GIT}/target/*.war |cut -d \/ -f 5 |cut -d \. -f 1)
ssh -o StrictHostKeychecking=no ${REMOTE_SERVER_USER}@${REMOTE_SERVER_IP} "rm -rf ${REMOTE_FILE_SERVER_PATH}/${TMP_VAR}*"
#Copy file to remote server
rsync --verbose --archive --compress-level=9 --stats ${DIRECTORY_FOR_CLONE_GIT}/target/*.war ${REMOTE_SERVER_USER}@${REMOTE_SERVER_IP}:${REMOTE_FILE_SERVER_PATH}
#Restart tomcat on remote server
if [ $? -ne 0 ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR, *.war don't copy to remote server" >> ${SCRIPT_LOG_PATH} && exit 0; fi
ssh -o StrictHostKeychecking=no ${REMOTE_SERVER_USER}@${REMOTE_SERVER_IP} "systemctl restart tomcat8"
if [ $? -ne 0 ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR, tomcat don't restart on remote server ${REMOTE_SERVER_IP}" >> ${SCRIPT_LOG_PATH} && exit 0; fi
#Test http code project
wget -O /dev/null -a ${DIRECTORY_FOR_CLONE_GIT}/testwget http://${REMOTE_SERVER_IP}:8080/grants/ && grep -c '200 OK' ${DIRECTORY_FOR_CLONE_GIT}/testwget
if [ $? -ne 0 ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR, project don't start correct" >> ${SCRIPT_LOG_PATH} && exit 0; fi
echo "$(date '+%Y-%m-%d %H:%M:%S') - Success finish deploy project ${GIT_PATH}" >> ${SCRIPT_LOG_PATH}
