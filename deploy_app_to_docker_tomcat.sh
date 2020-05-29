#!/bin/bash
#
#script deploy .war application from git_ver0.1
#
#For deploy we use 3 servers: SERVER_BUILD, SERVER_REGISTRY and SERVER_PROD.
#On server SERVER_BUILD install java and maven, download application from git,
#compile app in maven and build docker container with dockerfile, push to SERVER_REGISTRY.
#On SERVER_REGISTRY we start docker registry and keep container for transfer.
#On SERVER_PROD we only start container from SERVER_REGISTRY.
#
BUILD_IP=
REGISTRY_IP=
PROD_IP=
#
REGISTRY_USER="usertmp"
REGISTRY_PASS="passwordtmp7653"
CONTAINER_NAME="test1"
#
GIT_PATH="https://github.com/cp38510/java_Test.git"
DIRECTORY_FOR_CLONE_GIT="/tmp/git"
#
SCRIPT_LOG_PATH=/tmp/scriptdeploy.log
DATEFORM=$(date '+%Y-%m-%d %H:%M:%S')
#
#
function scriptdeploy {
#############################################################
#check enter servers IP's
if [ -z $BUILD_IP ] ; then echo "You don't set SERVER_BUILD IP" && exit 0; fi
if [ -z $REGISTRY_IP ] ; then echo "You don't set SERVER_REGISTRY IP" && exit 0; fi
if [ -z $PROD_IP ] ; then echo "You don't set SERVER_PROD IP" && exit 0; fi

#remove old RSA key's
ssh-keygen -R $BUILD_IP
ssh-keygen -R $REGISTRY_IP
ssh-keygen -R $PROD_IP
#############################################################
#SERVER_REGISTRY
SSHTMP1="ssh -o StrictHostKeychecking=no root@$REGISTRY_IP"
#update server
$SSHTMP1 "apt-get update > /dev/null"

#install docker
$SSHTMP1 "dpkg -s docker-ce > /dev/null 2>&1"
if [ $? -ne 0 ]; then $SSHTMP1 "curl https://get.docker.com/ | bash > /dev/null 2>&1"; fi

#check install docker
$SSHTMP1 "dpkg -s docker-ce > /dev/null 2>&1"
if [ $? -ne 0 ]; then echo "$DATEFORM - ERROR, docker didn't install on SERVER_REGISTRY" >> ${SCRIPT_LOG_PATH} && exit 0; fi

#create directories for docker
$SSHTMP1 "rm -rf /home/docker"
$SSHTMP1 "mkdir -p /home/docker/{data,auth}"

#create authentication docker registry file htpasswd
$SSHTMP1 "rm -rf /home/docker/auth/htpasswd"
$SSHTMP1 "docker run --entrypoint htpasswd registry -Bbn $REGISTRY_USER $REGISTRY_PASS > /home/docker/auth/htpasswd"

#check exist file htpasswd
$SSHTMP1 "test -f /home/docker/auth/htpasswd"
if [ $? -ne 0 ]; then echo "$DATEFORM - ERROR, file /home/docker/auth/htpasswd didn't create on SERVER_REGISTRY" >> ${SCRIPT_LOG_PATH} && exit 0; fi

#restart docker
$SSHTMP1 "systemctl restart docker"
if [ $? -ne 0 ]; then echo "$DATEFORM - ERROR, docker didn't restart on SERVER_REGISTRY" >> ${SCRIPT_LOG_PATH} && exit 0; fi

#stop and remove all runing container
TMPDOCKERLIST=$($SSHTMP1 "docker ps -a" |awk '{print $1}' |grep -vi container |tr '\n' ' ')
$SSHTMP1 "docker stop $TMPDOCKERLIST && docker rm $TMPDOCKERLIST"

#start docker registry container
$SSHTMP1 "docker run -d -p 5000:5000 --restart=always --name registry -v /home/docker/data:/var/lib/registry -v /home/docker/auth:/auth -e \"REGISTRY_AUTH=htpasswd\" -e \"REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm\" -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd registry > /dev/null"
if [ $? -ne 0 ]; then echo "$DATEFORM - ERROR, docker registry container didn't start on SERVER_REGISTRY" >> ${SCRIPT_LOG_PATH} && exit 0; fi

echo -e "\e[32m Deploy SERVER_REGISTRY Done \e[0m"

#############################################################
#SERVER_BUILD
SSHTMP2="ssh -o StrictHostKeychecking=no root@$BUILD_IP"
#update server
$SSHTMP2 "apt-get update > /dev/null"

#add java repository
$SSHTMP2 "add-apt-repository ppa:webupd8team/java -y > /dev/null"
if [ $? -ne 0 ]; then echo "$DATEFORM - ERROR, java repository didn't add on SERVER_BUILD" >> ${SCRIPT_LOG_PATH} && exit 0; fi

#update server
$SSHTMP2 "apt-get update > /dev/null"

#install java
$SSHTMP2 "dpkg -s oracle-java8-installer > /dev/null 2>&1"
if [ $? -ne 0 ]; then
$SSHTMP2 "echo \"oracle-java8-installer shared/accepted-oracle-license-v1-1 select true\" | sudo debconf-set-selections > /dev/null 2>&1"
$SSHTMP2 "apt-get install -y oracle-java8-installer > /dev/null 2>&1"
fi
#export JAVA_HOME directory
$SSHTMP2 "export JAVA_HOME=/usr/lib/jvm/java-8-oracle/"

#check install java
$SSHTMP2 "dpkg -s oracle-java8-installer > /dev/null 2>&1"
if [ $? -ne 0 ]; then echo "$DATEFORM - ERROR, java didn't install on SERVER_BUILD" >> ${SCRIPT_LOG_PATH} && exit 0; fi

#install maven
$SSHTMP2 "dpkg -s maven > /dev/null 2>&1"
if [ $? -ne 0 ]; then $SSHTMP2 "apt-get install maven -y > /dev/null 2>&1"; fi
if [ $? -ne 0 ]; then echo "$DATEFORM - ERROR, maven didn't install on SERVER_BUILD" >> ${SCRIPT_LOG_PATH} && exit 0; fi

#install git
$SSHTMP2 "dpkg -s git > /dev/null 2>&1"
if [ $? -ne 0 ]; then $SSHTMP2 "apt-get install git > /dev/null 2>&1"; fi
if [ $? -ne 0 ]; then echo "$DATEFORM - ERROR, git didn't install on SERVER_BUILD" >> ${SCRIPT_LOG_PATH} && exit 0; fi

#clone git repository
$SSHTMP2 "rm -rf /tmp/git"
$SSHTMP2 "git clone ${GIT_PATH} ${DIRECTORY_FOR_CLONE_GIT} > /dev/null"
if [ $? -ne 0 ]; then echo "$DATEFORM - ERROR, project don't clone from git on SERVER_BUILD" >> ${SCRIPT_LOG_PATH} && exit 0; fi

#package application
$SSHTMP2 "mvn package -f /tmp/git > /dev/null"
if [ $? -ne 0 ]; then echo "$DATEFORM - ERROR, application didn't package on SERVER_BUILD" >> ${SCRIPT_LOG_PATH} && exit 0; fi

#install docker
$SSHTMP2 "dpkg -s docker-ce > /dev/null 2>&1"
if [ $? -ne 0 ]; then $SSHTMP2 "curl https://get.docker.com/ | bash > /dev/null 2>&1"; fi
#check install docker
$SSHTMP2 "dpkg -s docker-ce > /dev/null 2>&1"
if [ $? -ne 0 ]; then echo "$DATEFORM - ERROR, docker didn't install on SERVER_BUILD" >> ${SCRIPT_LOG_PATH} && exit 0; fi

#create dockerfile
$SSHTMP2 "NAMEWAR=$(find /tmp/git/ -name \"*.war\" -exec basename \{} \;)"
$SSHTMP2 "echo -e \"FROM tomcat:8\nADD ./$NAMEWAR /usr/local/tomcat/webapps/\nEXPOSE 8080\nCMD [\042catalina.sh\042, \042run\042]\" > /tmp/dockerfile"
if [ $? -ne 0 ]; then echo "$DATEFORM - ERROR, dockerfile didn't create on SERVER_BUILD" >> ${SCRIPT_LOG_PATH} && exit 0; fi

#docker build container
$SSHTMP2 "cd $DIRECTORY_FOR_CLONE_GIT/target/ && docker build -t $REGISTRY_IP:5000/$CONTAINER_NAME:latest -f /tmp/dockerfile ."
if [ $? -ne 0 ]; then echo "$DATEFORM - ERROR, docker container didn't build on SERVER_BUILD" >> ${SCRIPT_LOG_PATH} && exit 0; fi

#create file for enable http connect to repository
$SSHTMP2 "echo -e \"{ '\042'insecure-registries'\042':['\042'$REGISTRY_IP:5000'\042'] }\" |tr -d '\047' > /etc/docker/daemon.json"
if [ $? -ne 0 ]; then echo "$DATEFORM - ERROR, file /etc/docker/daemon.json didn't create on SERVER_BUILD" >> ${SCRIPT_LOG_PATH} && exit 0; fi

#restart docker
$SSHTMP2 "systemctl restart docker"
if [ $? -ne 0 ]; then echo "$DATEFORM - ERROR, docker didn't restart on SERVER_BUILD" >> ${SCRIPT_LOG_PATH} && exit 0; fi

#login in remote docker registry
$SSHTMP2 "docker login --username=$REGISTRY_USER --password=$REGISTRY_PASS $REGISTRY_IP:5000"
if [ $? -ne 0 ]; then echo "$DATEFORM - ERROR, docker on SERVER_BUILD didn't login on remote SERVER_REGISTRY" >> ${SCRIPT_LOG_PATH} && exit 0; fi

#push docker container to remote docker registry
$SSHTMP2 "docker push $REGISTRY_IP:5000/$CONTAINER_NAME:latest"
if [ $? -ne 0 ]; then echo "$DATEFORM - ERROR, docker container didn't push to remote SERVER_REGISTRY" >> ${SCRIPT_LOG_PATH} && exit 0; fi

echo -e "\e[32m Deploy SERVER_BUILD Done \e[0m"

#############################################################
#SERVER_PROD
SSHTMP3="ssh -o StrictHostKeychecking=no root@$PROD_IP"
#update server
$SSHTMP3 "apt-get update > /dev/null"

#install docker
$SSHTMP3 "dpkg -s docker-ce > /dev/null 2>&1"
if [ $? -ne 0 ]; then $SSHTMP3 "curl https://get.docker.com/ | bash > /dev/null 2>&1"; fi
#check install docker
$SSHTMP3 "dpkg -s docker-ce > /dev/null 2>&1"
if [ $? -ne 0 ]; then echo "$DATEFORM - ERROR, docker didn't install on SERVER_PROD" >> ${SCRIPT_LOG_PATH} && exit 0; fi

#create file for enable http connect to repository
$SSHTMP3 "echo -e \"{ '\042'insecure-registries'\042':['\042'$REGISTRY_IP:5000'\042'] }\" |tr -d '\047' > /etc/docker/daemon.json"
if [ $? -ne 0 ]; then echo "$DATEFORM - ERROR, file /etc/docker/daemon.json didn't create on SERVER_PROD" >> ${SCRIPT_LOG_PATH} && exit 0; fi

#restart docker
$SSHTMP3 "systemctl restart docker"
if [ $? -ne 0 ]; then echo "$DATEFORM - ERROR, docker didn't restart on SERVER_PROD" >> ${SCRIPT_LOG_PATH} && exit 0; fi

#login in remote docker registry
$SSHTMP3 "docker login --username=$REGISTRY_USER --password=$REGISTRY_PASS $REGISTRY_IP:5000"
if [ $? -ne 0 ]; then echo "$DATEFORM - ERROR, docker on SERVER_PROD didn't login on remote SERVER_REGISTRY" >> ${SCRIPT_LOG_PATH} && exit 0; fi

#pull docker container from remote docker registry
$SSHTMP3 "docker pull $REGISTRY_IP:5000/$CONTAINER_NAME:latest"
if [ $? -ne 0 ]; then echo "$DATEFORM - ERROR, docker container didn't pull from remote SERVER_REGISTRY" >> ${SCRIPT_LOG_PATH} && exit 0; fi

#add tag to container
$SSHTMP3 "docker tag $REGISTRY_IP:5000/$CONTAINER_NAME:latest tomcat/$CONTAINER_NAME:latest"
if [ $? -ne 0 ]; then echo "$DATEFORM - ERROR, tag didn't add to cantainer on SERVER_PROD" >> ${SCRIPT_LOG_PATH} && exit 0; fi

#run docker container
$SSHTMP3 "docker run -d -p 8080:8080 --restart=always tomcat/$CONTAINER_NAME:latest"
if [ $? -ne 0 ]; then echo "$DATEFORM - ERROR, docker container didn't run on SERVER_PROD" >> ${SCRIPT_LOG_PATH} && exit 0; fi

#wait start container, before test
sleep 15s

#Test http code project
rm -rf /tmp/testwget
wget -O /dev/null -a /tmp/testwget http://$PROD_IP:8080/grants/ && grep -c ' 200 ' /tmp/testwget
if [ $? -ne 0 ]; then echo "$DATEFORM - ERROR, project didn't start correct on SERVER_PROD" >> ${SCRIPT_LOG_PATH} && exit 0; fi
rm -rf /tmp/testwget

echo -e "\e[32m Deploy SERVER_PROD Done \e[0m"
echo -e "\e[32m All task's well done! Go http://$PROD_IP:8080/grants/ \e[0m"

}
scriptdeploy
if [ $? -ne 0 ]; then echo "script execution ERROR! Look details ${SCRIPT_LOG_PATH}"; fi
