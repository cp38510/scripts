#!/bin/bash
#
#script_for_notify_the_owner_IP_about_abuse_v0.1
#
#file with ip - e-mail from WHOIS; example: 8.8.8.8 abuse@google.com
SPAMIPLIST=/tmp/spamiplist.txt
#file with log's abuse
SPAMLOGS=/tmp/logsmailserver.txt
#file for logging this script
SENDMAILLOG=/tmp/sendmail.log
#your text for subject mail
SUBJECTMAIL="SSH brute-force from your server"
#
#create list with uniq email's
cat $SPAMIPLIST |cut -d ' ' -f2|sort -u >/tmp/testtest111
UNIQLIST=/tmp/testtest111
#
while read MAILTO;
do
#create list IPs from mail
MAILIP="$(cat $SPAMIPLIST|grep $MAILTO|cut -d ' ' -f1)"
#change list IPs for search
IPFORGREP="$(echo $MAILIP|tr ' ' '\|')"
#grep logs for message
LOGS="$(cat $SPAMLOGS|egrep "$IPFORGREP")"
#create masseges for mail
MAILTEXT="Hello!\n\nAn attempt to brute-force account passwords(on our server mail.domain.com IP: 8.8.8.8) over SSH/FTP by a machine in your domain or in your network has been detected. Attached are the host who attacks and time / date of activity.\n\nPlease take the necessary action(s) to stop this activity immediately.\nIf you have any questions please reply to this email.\n\nHost attacker IP:\n$MAILIP\n\nLogs attack(time UTC+4):\n$LOGS\n\nSincerely,\nSystem administrator\nSurname Name\ndomain.com"
echo -e "${MAILTEXT}" |mail -aFrom:Surname_Name\<test@gmail.com\> -s "${SUBJECTMAIL}" "${MAILTO}"
if [ $? -ne 0 ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR, mail did'n sent to $MAILTO" >> ${SENDMAILLOG}; fi
#
done <"${UNIQLIST}"
