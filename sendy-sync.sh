#!/bin/bash
. config.sh
. lib/functions.sh
init_tmp
auth_user

users_md5=`cat remote/*.csv | md5sum | cut -d' ' -f1`
total_add=0
total_del=0

for afile in `ls local/lists/*/*.csv`; do
	# Extract list ID and name from Sendy lists data
	afile=${afile#local/lists/}
	afile=${afile%.csv}
	list=${afile%/*}
	name=${afile#*/}

	if [ "$list" -gt "7000" ]
	then 
		# Ignore list if was already processed with this users file
		if [ -d "local/versions/$users_md5/$list" ]; then
			continue
		fi
	
		echo -n "$list $name"

		# Update Sendy list with users data
		update_list "$list" "$name"
	
		# Sometimes auth fails and needs to be done again
		if [ $auth -eq 0 ]; then
			auth_user
			update_list "$list" "$name"
		fi
	
		# A second auth fail stops the process
		if [ $auth -eq 0 ]; then
			echo "Auth failed twice."
			exit 1
		fi
		
		add=$(cat tmp/$list/add-* 2>/dev/null | wc -l)
		del=$(cat tmp/$list/del-* 2>/dev/null | wc -l)
		echo " +$add -$del"
	
		total_add=$((total_add + add))
		total_del=$((total_del + del))
		
		# Update version for list
		rmdir -p local/versions/*/$list 2>/dev/null
		mkdir -p "local/versions/$users_md5/$list"
	fi
done

echo "Total modifications: +$total_add -$total_del"
