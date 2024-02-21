#!/bin/bash

# mikrotik-geo-addresslist.sh
# by Florian Faber 2024
# MIT License

c=$1
l=$2
sns=$3

function usage(){
        echo "Usage: mikrotik-geo-addresslist.sh <COUNTRY> <ADDRESS-LIST> [MORE-IPs]"

        echo " COUNTRY"
        echo "  A 2-letter country code like DE,GB,US,..."
        echo ""
        echo " ADDRESS-LIST"
        echo "  Name of the address-list. Will be cleared before adding IPs."
        echo ""
        echo " MORE-IPs (optional)"
        echo "  A comma-separated list of custom IPs or Subnets which should be added to the address-list"
        echo ""
        echo "Example:"
        echo "  mikrotik-geo-addresslist.sh DE Europe_IPs"
        echo "  mikrotik-geo-addresslist.sh GB Europe_IPs 192.168.0.0/16,172.16.0.0/24"
}

function prnt(){
        echo "/ip firewall address-list add address=$1 list=$l";
}

if [ "$c" = "-h" ] || [ "$c" = "--help" ] || [ "$c" = "" ] || [ "$l" = "" ]; then
        usage
        exit 1
fi

echo '/log info "Loading $l ipv4 address list"'
echo "/ip firewall address-list remove [/ip firewall address-list find list=$l]"

ips=$(wget -c -O - ftp://ftp.ripe.net/ripe/stats/$(date "+%Y")/delegated-ripencc-$(date "+%Y%m01").bz2 | bzcat | grep -i "|$c|ipv4|" | awk -F '|' '{print $4 "/" int(32 - log($5)/log(2))}')

if [ $? -ne 0 ]; then
        echo "Aborting..."
        exit 2
fi


for sn in $(echo $sns | tr "," "\n"); do
        prnt $sn
done

for ip in $ips; do
        prnt $ip
done
