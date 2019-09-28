#!/bin/bash

# Init tmp folder
function init_tmp()
{
	rm -rf tmp
	mkdir tmp
}

# Auth the user in Sendy and save authentication cookie
function auth_user()
{
	curl -s -b tmp/cookies.txt -c tmp/cookies.txt -d"email=$USER" -d"password=$PASS" -e $DOMAIN -L "$BASEURL/includes/login/main.php" > /dev/null
	auth=1
}

# Create a CSV dump with subscribers of a Sendy list at local/lists/[listID]/[name].csv
# Needs authentication
# Receives the list ID
function fetch_sendy_list()
{	
	local list=$1
	rm -rf "tmp/$list"
	mkdir "tmp/$list"
	echo "curl -s -b tmp/cookies.txt -c tmp/cookies.txt -D'tmp/$list/headers.txt' -e $DOMAIN '$BASEURL/includes/subscribers/export-csv.php?i=$APP&l=$list' | sed '/(0) Records Found!/d' - | sed '/^$/d' - > tmp/$list/list.csv"
	curl -s -b tmp/cookies.txt -c tmp/cookies.txt -D"tmp/$list/headers.txt" -e $DOMAIN "$BASEURL/includes/subscribers/export-csv.php?i=$APP&l=$list" | sed '/(0) Records Found!/d' - | sed '/^$/d' - > "tmp/$list/list.csv"
	local name=$(cat tmp/$list/headers.txt | grep Content-Disposition | rev | cut -d"-" -f2 | rev)
	if [ -z "$name" ]; then
		>&2 echo "ERROR: List $list update proccess failed."
		auth=0	
	else
		mkdir -p "local/lists/$list"
		mv -f "tmp/$list/list.csv" "local/lists/$list/${name}.csv"
	fi
}

# Updates Sendy list with users data
function update_list()
{
	local list=$1
	local name=$2
	local filename=

	rm -rf "tmp/$list"
	mkdir -p "tmp/$list"

	# Create sorted lists with users that matches list filter and sendy lists subscribers
	cat remote/*.csv | lib/filter_users.py $name | sort > "tmp/$list/users"

	sort "local/lists/$list/${name}.csv" > "tmp/$list/sendy"

	# Compare lists and add users not in subscribers list
	$(comm -23 tmp/$list/users tmp/$list/sendy | split -C$SPLIT_SIZE - tmp/$list/add-)
	for file in $(find tmp/$list -name add-*); do
		filename=`basename $file`
		curl -s -b tmp/cookies.txt -c tmp/cookies.txt -F "list_id=$list" -F "app=$APP" -F "cron=0" -F "csv_file=@$file;filename=${filename}.csv" -e $DOMAIN "$BASEURL/includes/subscribers/import-update.php"
	done

	# Compare lists and remove from Sendy lists subscribers not in filtered user list
	$(comm -13 tmp/$list/users tmp/$list/sendy | split -C$SPLIT_SIZE - tmp/$list/del-)
	for file in `find tmp/$list -name del-*`; do
		filename=`basename $file`
		cat $file | lib/delete_users.py | curl -s -b tmp/cookies.txt -c tmp/cookies.txt -F "list_id=$list" -F"app=$APP" -F"csv_file=@-;filename=${filename}.csv" -e $DOMAIN "$BASEURL/includes/subscribers/import-delete.php"
	done

	# Overrides Sendy list with new list
	mv -f "tmp/$list/users" "local/lists/$list/${name}.csv"	
}

