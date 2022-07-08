#!/bin/bash
PWD=`pwd`
# Display a list of folder modified
diff_dirs=`git diff --dirstat=files,0 HEAD | sed 's/^[ 0-9.]\+% //g'`
site=139.99.125.42
user=caothienlong
password=miq6UCTX
sitepath=g494190/gta5-fivem-txadmin/MysteriousRPCity/resources
echo $diff_dirs
for dir in $diff_dirs
do
    printf "@@@ Start SYNCING: \"$PWD/$dir\" \n ......Connecting to: $sitepath/$dir\n" 
    lftp -c "open $user:$password@$site; mirror --continue --reverse --delete \"$PWD/$dir\" \"$sitepath/$dir\""
    printf "### SYNCED \"$PWD/$dir\" !!! \n"
done
