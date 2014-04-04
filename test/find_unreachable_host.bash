#!/usr/bin/env bash
#
# Find last unreachable host listed

rm -f /tmp/t$$
netstat -rn | egrep '255\.255\.255\.0' | while [ ! -s /tmp/t$$ ] && read network ignore_rest
do
  echo Checking $network >&2
  fping -A -g $network/24 -a 2>&1 | grep 'ICMP Host Unreachable ' | tail -1 > /tmp/t$$
  cat /tmp/t$$ >&2
done
sed 's/.* //' /tmp/t$$ | grep .
