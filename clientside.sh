#!/bin/bash
#Script of client side checks

pinghost=8.8.4.4
webhookurl=https://hooks.slack.com/services/


function check-inet {
  ping -c2 > /dev/null 8.8.8.8 && ping=ok || ping=critical
  if [ $ping == ok ]
  then
    echo 0
  else
    echo 1
  fi
}

function check-eth-modems {
  for I in 1 2 3 4
  do
    gate=192.168.5.$I
    oldgate=$((I-1))
    if [ $oldgate -eq 0 ]; then oldgate=4; fi
    route del -host $pinghost gw 192.168.5.$oldgate
    route add -host $pinghost gw $gate
#    netstat -rn | grep '4.4'
    ping -c2 > /dev/null $pinghost && ping=ok || ping=critical
#traceroute -n 8.8.4.4
#echo $ping
    if [ $ping == critical ]
    then
      echo -e `date '+%F %H:%M:%S`"\n" >> /tmp/5.$I.pingoff
      > /tmp/5.$I.pingon
      if [ checkinet -eq 0 ]
      then
        msg=`date '+%F %H:%M:%S`"$pinghost is down"
        log
      fi
    fi
    if [ $ping == ok ] && [ `cat /tmp/5.$I.pingoff | wc -l` -gt 0 ]
    then
      echo `date '+%F %H:%M:%S`"\n" >> /tmp/5.$I.pingon
      > /tmp/5.$I.pingoff
      if [ `checkinet` -eq 0 ]
      then
        msg=`date '+%F %H:%M:%S`"$pinghost is up"
        log
      fi
    fi
done
}

function check-usb-modems {

}

function check-vtd-server {

}

function slack {
  echo "{\"channel\": \"#monitoring\", \"text\": \"$logmsg\"}" | http POST $webhookurl > /dev/null
}

function log {
  logmsg=`date '+%F %H:%M:%S`" $msg"
  echo $logmsg >> /var/log/slackping.log
#  slack
}

while true
do
  check-eth-modems
  check-usb-modems
  check-vtd-server
  sleep 15s
done
