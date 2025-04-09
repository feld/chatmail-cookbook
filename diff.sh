#!/bin/sh

FILES="$(cd files/default && ls)"

TEMPLATES="dovecot.conf main.cf master.cf"

for file in $FILES; do
  FILEPATH="$(find ../chatmail/www/src ../chatmail/cmdeploy/src/cmdeploy/ -type f -name $file -print)"
  echo $FILEPATH

  if [ -f $FILEPATH ]; then
    cp $FILEPATH files/default/$file
  fi

done


for file in $TEMPLATES; do

  diff -ruN ../chatmail/cmdeploy/src/cmdeploy/*/$file.j2 templates/default/$file.erb

done
