#!/bin/bash

if [ "$(ps -w | grep -v grep | grep sysmonitor.sh | wc -l)" -gt 2 ]; then
	exit 1
fi

sleep_unit=1
NAME=sysmonitor
APP_PATH=/usr/share/$NAME

uci_get_by_name() {
	local ret=$(uci get $1.$2.$3 2>/dev/null)
	echo ${ret:=$4}
}

uci_set_by_name() {
	uci set $1.$2.$3=$4 2>/dev/null
	uci commit $1
}

ping_url() {
	local url=$1
	for i in $( seq 1 3 ); do
		status=$(ping -c 1 -W 1 $url | grep -o 'time=[0-9]*.*' | awk -F '=' '{print$2}'|cut -d ' ' -f 1)
		[ "$status" == "" ] && status=0
		[ "$status" != 0 ] && break
	done
	echo $status
}

check_ip() {
	if [ ! -n "$1" ]; then
		#echo "NO IP!"
		echo ""
	else
 		IP=$1
    		VALID_CHECK=$(echo $IP|awk -F. '$1<=255&&$2<=255&&$3<=255&&$4<=255{print "yes"}')
		if echo $IP|grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$">/dev/null; then
			if [ ${VALID_CHECK:-no} == "yes" ]; then
				# echo "IP $IP available."
				echo $IP
			else
				#echo "IP $IP not available!"
				echo ""
			fi
		else
			#echo "IP is name convert ip!"
			dnsip=$(nslookup $IP|grep Address|sed -n '2,2p'|cut -d' ' -f2)
			if [ ! -n "$dnsip" ]; then
				#echo "Inull"
				echo $test
			else
				#echo "again check"
				echo $(check_ip $dnsip)
			fi
		fi
	fi
}
[ $(ifconfig |grep br-lan|cut -d' ' -f9) == 'A4:2B:8C:15:DE:94' ] && {
d=$(date "+%Y-%m-%d %H:%M:%S")
echo $d": ip=192.168.1.120" >> /var/log/sysmonitor.log
uci set network.wan.ipaddr='192.168.1.120'
uci commit network
ifup wan
}

ipold='888'
dnsname="music111.ddnsfree.com"
music111="888"
while [ "1" == "1" ]; do #死循环
	status=$(/usr/bin/wget -qO- 'http://nas:8080/ip6.html')
	[ -n "$status" ] && {
	[ ! $status == $music111 ] && {
		music111=$status
		sed -i "/$dnsname/d" /etc/hosts
		echo $status' '$dnsname >> /etc/hosts
		/etc/init.d/dnsmasq restart &
	}
	}
	ipv6=$(ip -o -6 addr list eth0.2 | cut -d ' ' -f7 | cut -d'/' -f1 |head -n1)
	[ ! $ipold == $ipv6 ] && {
		d=$(date "+%Y-%m-%d %H:%M:%S")
		echo $d": ip6="$ipv6 >> /var/log/sysmonitor.log
		ipold=$ipv6
		/usr/share/sysmonitor/sysapp.sh getip6
	}
	homeip=$(uci_get_by_name $NAME sysmonitor homeip 0)
	vpnip=$(uci_get_by_name $NAME sysmonitor vpnip 0)
	gateway=$(check_ip $(route |grep default|sed 's/default[[:space:]]*//'|sed 's/[[:space:]].*$//'))
	status=$(ping_url $vpnip)
	if [ "$status" == 0 ]; then
		if [ $gateway == $vpnip ]; then
			d=$(date "+%Y-%m-%d %H:%M:%S")
			echo $d": gateway="$homeip >> /var/log/sysmonitor.log
			uci set network.wan.gateway=$homeip
			uci set network.wan.dns=$homeip
			uci commit network
			ifup wan
			/etc/init.d/odhcpd restart
		fi
	else
		if [ $gateway == $homeip ]; then
			d=$(date "+%Y-%m-%d %H:%M:%S")
			echo $d": gateway="$vpnip >> /var/log/sysmonitor.log
			uci set network.wan.gateway=$vpnip
			uci set network.wan.dns=$vpnip
			uci commit network
			ifup wan
			/etc/init.d/odhcpd restart
		fi
	fi

	[ $(uci_get_by_name $NAME sysmonitor enable 0) == 0 ] && exit 0
	
	num=0
	while [ $num -le 10 ]; do
		sleep $sleep_unit
		[ $(uci_get_by_name $NAME sysmonitor enable 0) == 0 ] && exit 0
		let num=num+sleep_unit

		if [ -f "/tmp/sysmonitor" ]; then
			rm /tmp/sysmonitor
			num=50
		fi
	done
done

