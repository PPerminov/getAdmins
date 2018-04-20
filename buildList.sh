#!/bin/bash
rm -rf users result.csv

for file in files/*
do
  name=$(echo $file | awk -F'/' '{print $NF}')
  ADMINS=$(cat $file | tr "A-Z" "a-z" | grep -iv 'support' | grep -iv "администратор" | grep -iv admin | grep -iv administrator | tr -d '"' | sort -u  )
  while read line
  do
    # echo "$line"
    data=$(ldapsearch -E pr=10000000/noprompt -s sub -LLL -h 127.0.0.1 -b 'DC=ad,DC=ies-holding,DC=com' -D "CN=User,DC=perminov,DC=im" -W  "(sAMAccountName=$line)" | perl -p00e 's/\r?\n //g')
    linesCount=$(echo "$data" | wc -l)
    if [[ $linesCount -le 5 ]]
    then
      continue
    else
      TITLE=$(echo "$data" | grep 'title:' | awk -F': ' '{print $2}' | base64 -d)
      FIRM=$(echo "$data" | grep 'company:' | awk -F': ' '{print $2}' | base64 -d)
      DEP=$(echo "$data" | grep 'department:' | awk -F': ' '{print $2}' | base64 -d)
      NAME=$(echo "$data" | grep 'cn:' | awk -F': ' '{print $2}' | base64 -d)
      echo $name';'"$line"';'$NAME';'$TITLE';'$DEP';'$FIRM >> result.csv
    fi
  done <<< "$ADMINS"


done
