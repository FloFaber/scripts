#!/bin/bash

# mikrotik-geo-addresslist.sh
# (c) Florian Faber 2024
# MIT License

v4=1
v6=1

function usage(){
	echo "Download and parse IP-lists from ripe.net and output them into MikroTik-commands to create an address-list."
        echo "Usage: $(basename $0) [-4] [-6] [-a more-IPs] -c <countries> -n <address-list>"
	echo " Options:"
	echo "  -4              IPv4 only (optional)"
	echo "  -6              IPv6 only (optional)"
	echo "  -a <IPs>        A comma-separated list of additional (custom) IPs/Subnets (optional)"
	echo "  -c <countries>  A comma-separated list of 2-letter country codes like DE,GB,US,..."
	echo "  -n <name>       Name of the address-list"
	echo "  -h              Print this message"
        echo ""
        echo "Example:"
        echo "  $(basename $0) -4 -c CH,AT,DE -n CHAD_V4"
        echo "  $(basename $0) -a 192.168.0.0/16,1.2.3.4 -c GB -n BLACKLIST"
}

function prnt(){
        echo "/ip firewall address-list add address=$1 list=$name";
}


while getopts ":46ha:n:c:" opt; do
	case ${opt} in
		4)
			v6=0
			;;
		6)
			v4=0
			;;
		a)
			additional=${OPTARG}
			;;
		n)
			name=${OPTARG}
			;;
		c)
			countries=${OPTARG}
			;;
		h)
			usage
			exit 0
			;;
		:)
			echo "Option -${OPTARG} requires argument."
			exit 1
			;;
		?)
			echo "Invalid option: -${OPTARG}"
			exit 1
			;;
	esac
done


if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ "$1" = "" ]; then
        usage
        exit 1
fi

: ${countries:?Missing -c} ${name:?Missing -n}


echo "/log info \"Loading $name ipv4 address list\""
echo "/ip firewall address-list remove [/ip firewall address-list find list=$name]"

# custom subnets
for sn in $(echo $additional | tr "," "\n"); do
        prnt $sn
done

ip_list=$(wget -c -O - ftp://ftp.ripe.net/ripe/stats/$(date "+%Y")/delegated-ripencc-$(date "+%Y%m01").bz2 | bzcat)

regex="ipv(4|6)"
if [ "$v4" -eq "1" ]; then
	regex="ipv4"
elif [ "$v6" -eq "1" ]; then
	regex="ipv6"
fi

# for each given country
for c in $(echo $countries | tr "," "\n"); do
	ips=$(grep -Ei "\|$c\|$regex\|" <<< "$ip_list" | awk -F '|' '{print $4 "/" int(32 - log($5)/log(2))}')

	if [ $? -ne 0 ]; then
	        echo "Aborting..."
	        exit 2
	fi

	# foreach ip/subnet in country
	for ip in $ips; do
	        prnt $ip
	done
done
