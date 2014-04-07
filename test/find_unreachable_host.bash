#!/bin/bash
#
# Find last unreachable host listed

rm -f /tmp/t$$
netstat -rn | egrep '255\.255\.255\.0' | while [ ! -s /tmp/t$$ ] && read network ignore_rest
do
  echo Checking $network >&2
  fping -A -g $network/24 -a 2>&1 | grep 'ICMP Host Unreachable ' | tail -1 > /tmp/t$$
  cat /tmp/t$$ >&2
done
ret=1
if [ -s /tmp/t$$ ]
then
  sed -n 's/.* //p' /tmp/t$$
  ret=0
elif [ -f /tmp/t$$ ]
then
  echo 'Was not able to find an unreachable host on the network' >&2
else
  echo 'Was not able to find a class C network to check' >&2
fi
rm -f /tmp/t$$
exit $ret
