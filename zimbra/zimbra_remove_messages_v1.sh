#!/bin/bash
#version 0.1
#
ZIMBRA_BIN=/opt/zimbra/bin
MAIL_DOMAIN=mail.ru

echo "Enter the mailbox name, use format: test@mail.ru:"
read THEACCOUNT
# Checking the existence of an account
$ZIMBRA_BIN/zmprov -l gaa $MAIL_DOMAIN |grep -xc $THEACCOUNT > /dev/null 2>&1
if [ $? -ne 0 ]; then "echo ERROR, account $THEACCOUNT not found" && exit 0; fi

echo "Enter the start date for the message deletion period, in mm/dd/yyyy format. Example: 04/1/2018"
read THEDATE1
if [ -z "$THEDATE1" ]; then echo "ERROR, variable not entered" && exit 0; fi
if [[ ! "$THEDATE1" =~ ^[0-9]{2}/[0-9]{2}/[0-9]{4}$ ]]; then echo "ERROR, invalid date format, use format: mm/dd/yyyy" && exit 0; fi

echo "Enter the end date for the message deletion period, in mm/dd/yyyy format. Example: 04/21/2018"
read THEDATE2
if [ -z "$THEDATE2" ]; then echo "ERROR, variable not entered" && exit 0; fi
if [[ ! "$THEDATE2" =~ ^[0-9]{2}/[0-9]{2}/[0-9]{4}$ ]]; then echo "ERROR, invalid date format, use format: mm/dd/yyyy" && exit 0; fi

echo "You will now be deleting ALL(Input and output) messages in $THEDATE1 - $THEDATE2 for $THEACCOUNT."
echo "Do you want to continue? (y/N): "
read ADD

themagic ()
{
rm -f /tmp/deleteOldMessagesList.txt; touch /tmp/deleteOldMessagesList.txt
rm -f /tmp/process.log; touch /tmp/process.log

for i in `$ZIMBRA_BIN/zmmailbox -z -m $THEACCOUNT search -l 1000 "after:$THEDATE1 before:$THEDATE2" |awk '{print $2}'| sed 1,4d`
do
        if [[ $i =~ [-]{1} ]]
        then
        MESSAGEID=${i#-}
        echo "deleteMessage $MESSAGEID" >> /tmp/deleteOldMessagesList.txt
        else
        echo "deleteConversation $i" >> /tmp/deleteOldMessagesList.txt
        fi
done

while [ -s /tmp/deleteOldMessagesList.txt ]
do
        $ZIMBRA_BIN/zmmailbox -z -m $THEACCOUNT < /tmp/deleteOldMessagesList.txt >> /tmp/process.log
        rm -f /tmp/deleteOldMessagesList.txt; touch /tmp/deleteOldMessagesList.txt
        for i in `$ZIMBRA_BIN/zmmailbox -z -m $THEACCOUNT search -l 1000 "after:$THEDATE1 before:$THEDATE2" |awk '{print $2}'| sed 1,4d`
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
read -p "Completed. Run again for other user (y/n)? " REPLY
if [[ $REPLY =~ ^[Yy]$ ]]; then exec $0; else ADD=n; fi
}

while expr "$ADD" : ' *[Yy].*' > /dev/null
do themagic
done
