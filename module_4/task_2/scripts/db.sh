#bin/bash -
#===============================================================================
#
#          FILE: db.sh
#
#         USAGE: ./db.sh
#
#   DESCRIPTION: 
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 03/11/2023 12:14:49 PM
#      REVISION:  ---
#===============================================================================

FILE_NAME=users.db

if [[ $1 != help && $1 != "" && ! -f ./users.db  ]]
then
	read -r -p "users.db does not exist. Do you want to create it? [Y/n]" answer
	if [[ $answer =~ ^(yes|y)$ ]]
	then 
		touch $FILE_NAME
		echo "File ${FILE_NAME} is created"
	else 
		echo "File ${FILE_NAME} must be created to continue. Try again"
		exit 1
	fi
fi

function validateLatinLetters {
	if [[ $1 =~ ^[A-Za-z_]+$ ]] 
	then return 0;
	else return 1;
	fi

}

function add {
 read -p 'Username:' username
 validateLatinLetters $username
	if [[ $? == 1 ]]
	then 
		echo 'User name should consist of latin letters only. Try again'
		exit 1
	fi

 read -p 'Role:' role
 validateLatinLetters $role
  if [[ $? == 1 ]]
  then
    echo 'Role  should consist of latin letters only. Try again'
    exit 1
  fi

	echo "${username}, ${role}" | tee -a $FILE_NAME 
}

function help {
	echo 'Use db.sh'
	echo
	echo 'List of commands:'
	echo
	echo 'add: Add new line to the users.db'
	echo
	echo 'backup: Create a backup of users.db file'
	echo
	echo 'find: Find user from users.db file'
	echo
	echo 'list: Prints all users from users.db'
}

function restore {
	latestBackupFile=$(ls *-$FILE_NAME.backup | tail -n 1)

	if [[ ! -f $latestBackupFile ]]
	then 
		echo 'No backups'
		exit 1
	fi

	cat $latestBackupFile > $FILE_NAME

	echo 'Backup is restored'
}

function backup {
	backupFileName=$(date +'%Y-%m-%d-%H-%M-%S')-users.db.backup
	cp $FILE_NAME $backupFileName
	echo "Backup is created: ${backupFileName}"
}

inverseParam=$2

function list {
	if [[ $inverseParam == "--inverse" ]]
	then
		cat --number $FILE_NAME | tac
	else
		cat --number $FILE_NAME
	fi
}

function find {
	read -p 'Enter query to search' query
	local searchResults=`grep -i $query $FILE_NAME`

	if [[ -z $searchResults ]]
	then
		echo 'User not found'
		exit 1
	else 
		echo $searchResults
	fi
}

case $1 in
help | '')
		help
		;;

add)
	add
	;;
backup)
	backup
	;;
restore)
	restore
	;;
find)
	find
	;;
list)
	list
	;;

*)
	echo 'others'
	;;

esac #--- end of case ---

