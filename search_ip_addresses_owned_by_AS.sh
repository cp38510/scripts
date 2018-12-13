#!/bin/bash
#script to search all domain IP-addresses
#
#remove temporary files, if they exist
rm -rf /tmp/tmpvartmp777
rm -rf /tmp/tmpvartmp778
#find domain IP-addresses
dig $1 +short > /tmp/tmpvartmp777
#start search all AS(Autonomous System) owned by IP-addresses
while read ipaddr;
do
whois $ipaddr | grep origin | awk {'print $2'} > /tmp/tmpvartmp778
done < /tmp/tmpvartmp777
#sort unique AS(Autonomous System)
ASUNIQ="$(cat /tmp/tmpvartmp778 |sort -u)"
#find all IP-addresses owned by AS(Autonomous System)
whois -h whois.ripe.net -i origin $ASUNIQ | grep route | awk '{print $2}' | grep -ivE "vk|:" |egrep -v '[a-z]|[A-Z]'
#remove temporary files
rm -rf /tmp/tmpvartmp777
rm -rf /tmp/tmpvartmp778
echo "Done!"
