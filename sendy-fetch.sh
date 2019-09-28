#!/bin/bash
. config.sh
. lib/functions.sh

init_tmp

auth_user

for list in $(cat local/*.lists); do
        if [ "$list" -gt "7000" ]
	then
		echo "$list"
		fetch_sendy_list "$list"

		# Sometimes its needed to auth again
		if [ $auth -eq 0 ]; then
			auth_user
			fetch_sendy_list "$list"
		fi

		# A second auth fail stops process
		if [ $auth -eq 0 ]; then
			echo "Auth failed twice."
			exit 1
		fi
	fi
done

