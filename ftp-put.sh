#!/bin/bash

# Variables
PWD=`pwd`
site=139.99.125.133
user=caothienlong
password=miq6UCTX
#TODO Check local resources path
#TODO Check sitepath
sitepath=/g501621/gta5-fivem-txadmin/MysteriousRPCity/resources
versionfile_path=.git/logs
versionfile=HEAD
local_commit=
ftp_commit=

####################################
### GET FTP CURRENT COMMIT CHANGESET
####################################

getCurrentFTPChangeset() {
    # Retrieve FTP GameServer current commit
    lftp -c "open $user:$password@$site; get $sitepath/$versionfile_path/$versionfile"
    if [ ! -f $versionfile ]; then
        echo "@@@ ERROR: $versionfile file not found at ftp server"
        exit -1
    fi
    ftp_commit=`tail -n 1 $versionfile | cut -d " " -f 2`
    printf "\n\n\@@@ @@@ @@@ FTP Server commit: $ftp_commit\n\n\n"
}

#################################################
### UPDATE FTP COMMIT CHANGESET WITH LOCAL COMMIT
#################################################

updateCurrentFTPChangeset() {
    # Retrieve Local commit
    local_commit=`git log --pretty=oneline -1 | cut -d " " -f 1`

    if [ $local_commit != $ftp_commit ]; then
        echo "Update FTP current commit changeset"
        lftp -c "open $user:$password@$site; put -c $versionfile_path/$versionfile -o $sitepath/$versionfile_path/$versionfile"
    else
        echo "Same commit as local. Nothing updated!"
    fi
}

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
        cmd=$cmd"rm $sitepath/$file; "
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

    # List of Removed files that not staged
    removed_files=`git diff --name-only --no-renames --diff-filter=D $ftp_commit`

    # Append files removed to cmd above, to put remove files per connection opened
    for file in $removed_files
    do
        cmd=$cmd"rm -f $sitepath/$file; "
    done

    # List of NEW ADDED DIRs that UNTRACKED before
    removed_dirs=`git diff --name-only --no-renames --diff-filter=D $ftp_commit | awk -F "/*[^/]*/*$" '{ print ($1 == "" ? "." : $1); }' | sort | uniq`

    # Append dirs removed to cmd above, to remove dirs on remote per connection opened
    for dir in $removed_dirs
    do
        # If dir is empty, remove it at remote as well
        if [ ! -d $dir ]; then
            cmd=$cmd"rm -r -f $sitepath/$dir; "
        fi
    done

    printf "@@@ Start SYNCING removed files to: $sitepath\n" 
    lftp -c "$cmd"
    printf "### SYNCED!!! \n\n\n"
}

#####################
### MANUAL Sync files
#####################

syncFiles() {
    # Init open connection cmd
    cmd="open $user:$password@$site; "

    file=$1
    if [ -f $file ]; then
        cmd=$cmd"rm $sitepath/$file; "
        cmd=$cmd"put -c $file -o $sitepath/$file; "
    else
        cmd=$cmd"mirror --continue --reverse --delete $file $sitepath/$file"
    fi

    printf "@@@ Start SYNCING files to: $sitepath\n" 
    lftp -c "$cmd"
    printf "### SYNCED!!! \n\n\n"
}

# Manual sync file
# TODO UPDATE LATER
# If input is not empty
if [ ! -z $1 ]; then
    syncFiles $1
    exit 1
fi

getCurrentFTPChangeset

syncModifiedFiles

syncAddedFiles

syncRemovedFiles

updateCurrentFTPChangeset

# Clean up
rm $versionfile