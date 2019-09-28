RUNNING="update-users-running"
if [ -f $RUNNING ]; then
	echo "Script is already running."
	exit 1
fi

touch $RUNNING	
bash /var/www/vhosts/envios.masmadrid.org/sendy-sync/dump_emails.sh && scp /var/www/vhosts/participa.masmadrid.org/participa/tmp/sendy/users.csv /var/www/vhosts/envios.masmadrid.org/sendy-sync/remote/users.csv && bash /var/www/vhosts/envios.masmadrid.org/sendy-sync/sendy-sync.sh
rm $RUNNING
