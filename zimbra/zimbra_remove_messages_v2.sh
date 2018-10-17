#!/bin/bash
#version 0.2
#
ZIMBRA_BIN=/opt/zimbra/bin
MAIL_DOMAIN=mail.ru
USER_LIST=/tmp/userlist.txt
#Enter the start date for the message deletion period, in mm/dd/yyyy format. Example: 04/1/2018
THEDATE1=05/20/2013
#Enter the end date for the message deletion period, in mm/dd/yyyy format. Example: 04/21/2018
THEDATE2=01/01/2017
#
cat $USER_LIST | while read line
do
#
rm -f /tmp/deleteOldMessagesList.txt
touch /tmp/deleteOldMessagesList.txt
rm -f /tmp/process.log
touch /tmp/process.log
for i in `$ZIMBRA_BIN/zmmailbox -z -m $line search -l 1000 "after:$THEDATE1 before:$THEDATE2" |awk '{print $2}'| sed 1,4d`
do
        if [[ $i =~ [-]{1} ]]
        then
        MESSAGEID=${i#-}
        echo "deleteMessage $MESSAGEID" >> /tmp/deleteOldMessagesList.txt
        else
        echo "deleteConversation $i" >> /tmp/deleteOldMessagesList.txt
        fi
done
#
while [ -s /tmp/deleteOldMessagesList.txt ]
do
        $ZIMBRA_BIN/zmmailbox -z -m $line < /tmp/deleteOldMessagesList.txt >> /tmp/process.log
        rm -f /tmp/deleteOldMessagesList.txt
        touch /tmp/deleteOldMessagesList.txt
        for i in `$ZIMBRA_BIN/zmmailbox -z -m $line search -l 1000 "after:$THEDATE1 before:$THEDATE2" |awk '{print $2}'| sed 1,4d`
        do
        if [[ $i =~ [-]{1} ]]
        then
        MESSAGEID=${i#-}
        echo "deleteMessage $MESSAGEID" >> /tmp/deleteOldMessagesList.txt
        else
        echo "deleteConversation $i" >> /tmp/deleteOldMessagesList.txt
        fi
        done

done
#
echo "Messages in $line delete" >> /tmp/deleteProcess.txt
echo "Done!"
done
