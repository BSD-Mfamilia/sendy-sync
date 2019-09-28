. config.sh
. lib/functions.sh

# create location lists
mysql sendy -u root -s -N < remote/update_lists.sql > local/lists.lists

init_tmp

# compare local lists with Sendy lists, and remove local lists not in Sendy
ls local/lists/ > tmp/fs_lists.csv
sort local/lists.lists > tmp/sendy_lists.csv
for list in `comm -23 tmp/fs_lists.csv tmp/sendy_lists.csv`; do
	rm -rf "local/lists/$list"
done
