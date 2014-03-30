#!/usr/bin/env bash
#
# . test/setup_ubuntu.bash # will setup env variables after testing

set -x
if ping -n -c2 192.0.2.1 2>&1 | egrep -i network.*unreachable
then
    echo Unreachable network is already setup
else
    sudo ip route add unreachable 192.0.2.1
fi
if ping -n -c2 192.0.2.2 2>&1 | egrep -i host.*unreachable
then
    echo Unreachable network is already setup
else
    sudo iptables -I OUTPUT -d 192.0.2.2 -j REJECT --reject-with=icmp-host-unreachable
fi
if egrep '#disable' /etc/xinetd.d/echo
then
    echo echo service is setup
else
  sudo apt-get update -qq
  sudo apt-get install xinetd -y -qq
  sudo sed -i.bak -e 's/disable/#disable/' /etc/xinetd.d/echo
  sudo service xinetd restart
fi

echo Port 1001 should not be in LISTEN mode
netstat -l -n | egrep ':1001 '


set -e
echo Checking everything is working as expected ...

ping -n -c2 192.0.2.1 2>&1 | egrep -i network.*unreachable
ping -n -c2 192.0.2.2 2>&1 | egrep -i host.*unreachable
sh -c '! ping -n -c2 144.140.108.23'
sh -c '! (ping -n -c2 144.140.108.23 2>&1 | egrep -i unreachable )'
netstat -l -n | egrep ':7 '
netstat -l -n | egrep ':22 '

export UNREACHABLE_HOST=192.0.2.1 UNREACHABLE_ROUTE=192.0.2.2

set +x
set +e