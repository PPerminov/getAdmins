#!/bin/bash


function WORKER() {
  touch ids/$2
  while read line
  do
    # echo "$line"
    ping -n -c 1 -W 1 "$line" &>/dev/null
    if [[ $? -ne 0 ]]
    then
      echo $line >> wars/$2
    else
      d1=$(wmic -U 'Admin1%'$3 //"$line" 'select * from win32_groupuser')
      if [[ $? -ne 0 ]]
      then
        d1=$(wmic -U 'Admin2%'$4 //"$line" 'select * from win32_groupuser')
        if [[ $? -ne 0 ]]
        then
          echo "$line" Access Denied >> wars/$2
          continue
        fi
      fi
      echo "$d1" | egrep -i 'Администраторы|Administrators' | awk -F'|' '{print $2}' | grep -v -i group.domain | awk -F'=' '{print $NF}'>> files/"$line"
    fi
  done <<< "${!1}"
  rm -rf ids/$2
}

function main() {
  CHECK=0
  read -s -p "Password 1 " PASS1
  read -s -p "Password 2 " PASS2
  rm -rf files ids wars
  mkdir ids files	wars
  date=$(date +%s)
  tar cvzf ../$date.tgz *
  while read lines
  do
    ID=$(cat /dev/urandom | tr -dc "0-9" | fold -b5 | head -n 1)
    WORKER "$lines" $ID $PASS1 $PASS2 &
    echo $ID >> wlist.tmp
  done <<< "$WARS"
  while [[ $CHECK -eq 0 ]]
  do
    if [[ -z $(ls ids) ]]
    then
      CHECK=666
      echo "Done"
      exit 0
    fi
  done
}

function prepare() {
  returnedWARS=$(cat $1 | awk '{print $1}' | sort -u)
  WSes=50
  COUNT=$(echo "$returnedWARS" | wc -l)
  curr=1
  ray=1
  baseName=WARS
  tmp=./tmp
  rm $tmp
  while [[ $curr -le $COUNT ]]
  do
    currentArrayName="$baseName""$ray"
    WARS="$currentArrayName
    $WARS"
    nextPatch=$(echo "$returnedWARS" | tail -n +$curr | head -n $WSes)
    echo "$currentArrayName""="'"'"$nextPatch"'"' >> $tmp
    let curr=curr+$WSes
    let ray=$ray+1
  done
  . $tmp
}

if [[ $1 == 'again' ]]   # "again" is for research on problem workstations. It uses data from previously saved in WARS folder
then
  prepare './wars/*'
  main
else
  prepare $1
  main
  # echo 1
fi
