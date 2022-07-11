#!/bin/bash

# Variables
PWD=`pwd`
site=139.99.125.42
user=caothienlong
password=miq6UCTX
#TODO Check local resources path
#TODO Check sitepath
sitepath=g494190/gta5-fivem-txadmin/MysteriousRPCity/resources
versionfile=main

# Retrieve FTP GameServer current commit
lftp -c "open $user:$password@$site; get $sitepath/.git/refs/heads/$versionfile"
if [ ! -f $versionfile ]; then
    echo "@@@ ERROR: main file not found at ftp server"
    exit -1
fi
ftp_commit=`tail -n 1 main | cut -d " " -f 2`
echo "FTP Server commit: $ftp_commit"

#######################
### SYNC Modified files
#######################

syncModifiedFiles() {
    # Init open connection cmd
    cmd="open $user:$password@$site; "

    # List of modified files
    diff_files=`git diff --name-only --no-renames --diff-filter=M $ftp_commit`

    # Append file to cmd above, to put all files per connection opened
    for file in $diff_files
    do
        cmd=$cmd"put -c $file -o $sitepath/$file; "
    done

    printf "@@@ Start SYNCING modifled files to: $sitepath\n" 
    lftp -c "$cmd"
    printf "### SYNCED!!! \n\n\n"
}

####################
### SYNC Added files
####################

syncAddedFiles() {
    # Init open connection cmd
    cmd="open $user:$password@$site; "

    # List of NEW ADDED DIRs that UNTRACKED before
    added_dirs=`git diff --name-only --no-renames --diff-filter=A --cached  $ftp_commit | awk -F "/*[^/]*/*$" '{ print ($1 == "" ? "." : $1); }' | sort | uniq`

    # Append added dirs to cmd above, to make new dirs on remote per connection opened
    for dir in $added_dirs
    do
        cmd=$cmd"mkdir -p -f $sitepath/$dir; "
    done

    # List of new Added files that untracked before
    added_files=`git diff --name-only --no-renames --diff-filter=A --cached $ftp_commit`

    # Append files to cmd above, to put all files per connection opened
    for file in $added_files
    do
        cmd=$cmd"put -c $file -o $sitepath/$file; "
    done

    printf "@@@ Start SYNCING added files to: $sitepath\n" 
    lftp -c "$cmd"
    printf "### SYNCED!!! \n\n\n"
}

######################
### SYNC Removed files
######################

syncRemovedFiles() {
    # Init open connection cmd
    cmd="open $user:$password@$site; "

    # List of NEW ADDED DIRs that UNTRACKED before
    added_dirs=`git diff --name-only --no-renames --diff-filter=A --cached  $ftp_commit | awk -F "/*[^/]*/*$" '{ print ($1 == "" ? "." : $1); }' | sort | uniq`

    # Append added dirs to cmd above, to make new dirs on remote per connection opened
    for dir in $added_dirs
    do
        cmd=$cmd"mkdir -p -f $sitepath/$dir; "
    done

    # List of new Added files that untracked before
    added_files=`git diff --name-only --no-renames --diff-filter=A --cached $ftp_commit`

    # Append files to cmd above, to put all files per connection opened
    for file in $added_files
    do
        cmd=$cmd"put -c $file -o $sitepath/$file; "
    done

    printf "@@@ Start SYNCING added files to: $sitepath\n" 
    lftp -c "$cmd"
    printf "### SYNCED!!! \n\n\n"
}

# Clean up
rm $versionfile