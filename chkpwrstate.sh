#!/bin/sh

PIDFILE=/mydev/chkpwrstate.pid
if [ -f $PIDFILE ]
then
  PID=$(cat $PIDFILE)
  ps -p $PID > /dev/null 2>&1
  if [ $? -eq 0 ]
  then
    echo "Process already running"
    exit 1
  else
    ## Process not found assume not running
    echo $$ > $PIDFILE
    if [ $? -ne 0 ]
    then
      echo "Could not create PID file"
      exit 1
    fi
  fi
else
  echo $$ > $PIDFILE
  if [ $? -ne 0 ]
  then
    echo "Could not create PID file"
    exit 1
  fi
fi

while read line; do
    echo $line | awk '
{
vmid[++c]=$1
name[c]=$2
file[c]=$3
guest[c]=$4
os[c]=$5
version[c]=$6
annotation[c]=$7
}
END{
  HOSTS="virtualHost0,VirtualHost1,VirtualHost2"
  split(tolower(HOSTS), List,",")
  for(i in List){
  }

  for(i=1;i<=c;i++){
  "echo $(vim-cmd vmsvc/power.getstate "vmid[i]")" | getline output[i]
  }
  for(i=1;i<=c;i++){
    if( output[i] ~ /off$/){
      for(j in List){
        if( tolower(name[i]) ~ tolower(List[j])){
          print name[i] "vmid:" vmid[i] " is off and in our list"
          system("vim-cmd vmsvc/power.on " vmid[i])
          system("/vmfs/volumes/1abe8cfb-10cc069d/pushover " name[i])
        }
      }
    }
  }



}
'
done <<EOF
`vim-cmd vmsvc/getallvms | awk 'NR > 1{print}'`
EOF

rm $PIDFILE
