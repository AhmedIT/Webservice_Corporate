#!/bin/bash
# FLOW 2 second : Sphinx index rotating and Sphinx configuration updating 
export TERM=dumb
bashname="Flow 2S Sphinx Rotate"
#FUNCTION allowing to log in a file
add_log()
{
  go_chown=0 
  if  [ ! -f $log_file ]; then
	 go_chown=1
	fi
	message=$(echo "$2" | tr "\n" " ")
  echo "$(date '+%Y-%m-%d %H:%M:%S');storelocator;uat;[$bashname] - $message;;CRP;CRPWS;storelocator_bash;en_US;;" >> $log_file
  #IF the log File does not exist
	if [ "$go_chown" -eq 1 ]; then 
	 chown apache:apache $log_file 
	fi
}
add_log_if_error()
{
	if [ uat ]; then
		add_log "ERROR" "uat"
	fi
}
sphinx_rotate()
{  
	cmd_rotate=$(/usr/bin/indexer uat --rotate --config $target_conf_file)
	case "$cmd_rotate" in
		*succesfully*) add_log "DEBUG" "Rotating OK uat index rotated : $cmd_rotate";;
		*)  add_log "ERROR" "Rotating command KO : $cmd_rotate";;
	esac 
}

go_rotate=0 
show_debug=1 

  lookup_conf_file="/data/www/uat-ws.chanel.com/www/sources/storelocator/conf/uat/sphinx.conf.php"
  target_conf_file="/etc/sphinx/sphinx.conf"
  backup_conf_file="/data/www/uat-ws.chanel.com/www/sources/storelocator/conf/uat/sphinx.conf.$(date '+%Y%m%d%H%M%S').php"
  lookup_rotate_file="/data/www/uat-ws.chanel.com/www/sources/storelocator/sphinx_rotate"
  log_file="/data/logs/chanel_service/storelocator/$(date '+%Y-%m-%d')_log.csv"

add_log "DEBUG" "***** Begin Flow 2S Sphinx Rotate *****"
# Look up for new sphinx.conf
if [ -f $lookup_conf_file ]; then
	add_log "DEBUG" "***** Processing new Sphinx Configuration *****"
	#backup the old sphinx.conf
	add_log "DEBUG" "Backup the old sphinx.conf to : $backup_conf_file"
	cmd_cp=$(cp $target_conf_file $backup_conf_file)
	add_log_if_error "$cmd_cp"
	#copy
	add_log "DEBUG" "Replace config file"
	cmd_mv=$(mv -f $lookup_conf_file $target_conf_file)
	add_log_if_error "$cmd_mv"
	#Rotating planified
	go_rotate=1
fi

# Look up for new sphinx_rotate
if [ -f "$lookup_rotate_file" -o "$go_rotate" -eq 1 ]; then
	go_rotate=1
	#Rotating 
	add_log "DEBUG" "***** Reindexing Sphinx ***** "
	sphinx_rotate pos
	sphinx_rotate pos_translations
	sphinx_rotate pos_products
	sphinx_rotate pos_cities
	sphinx_rotate pos_states
	sphinx_rotate pos_services
	sphinx_rotate pos_products_collection
	sphinx_rotate pos_animations
 	if [ -f "$lookup_rotate_file" ]; then
		#delete lookup files
		add_log "DEBUG" "Deleting lookup file"
		cmd_rm=$(rm $lookup_rotate_file)
		add_log_if_error "$cmd_rm"
	fi
fi

#log a message if nothing happens
if [ $go_rotate -eq "0" -a "$show_debug" -eq 1 ]; then 
	add_log "DEBUG" "Nothing to do"
fi
add_log "DEBUG" "***** End Flow 2S Sphinx Rotate *****"