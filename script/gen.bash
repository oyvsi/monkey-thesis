#!/bin/bash
#
# This script is used to generate hosts for Icinga/Nagios
#   its NOT ment to replace manual labour its merly a tool 
#   to simplify the adding of multiple hosts, from a common file format.
#
# MonKey 2013
#
#
## USAGE
#	Run this script and generate hosts from a supplyed CSV file.
#	The first argument is the location of the CSV file, this needs to be supplyed
#		The CSV file needs to columns at minimum, the first has to be hostname
#		  the secound column has to be the IP Address
#		The third and forth columns are optional. and the default value can be changed.
#		  the third column is hostgroup
#		  the fourth column is the generic
#	The secound argument is the path to where the files are to be generated.
#	  If this is not supplyed, the hosts will be generated in your working directory.
#
#
## CSV Format:
#	hostname,address,hostgroup,generic
#	dc1,10.0.0.1,windows_servers,generic_service
#	dc2,10.0.0.2,,generic_service
#	mail1,10.0.0.3
#	print1,10.0.0.4,print_servers
#	apache1,10.0.0.5,windows_servers;print_servers;terminal_servers
#
#
## Arguments
# $1 = Path to csv file
# $2 = Path to generate hosts

# Default value variables

defaultGeneric="generic_ts"			# Default, not used if supplyed
defaultHostgroup="windows_servers"	# Default, not used if supplyed


################################################
## Nothing should be changed below this line  ##
################################################

if [ -z "$1" ]; then				# Check if CSV file is supplyed
	echo -e "\tThis script generates config files for Icinga/Nagios"
	echo -e "\t Supply a CSV file with format hostname,address (See script for more options)"
    echo -e "\tFirst argument has to be the CSV file"
	echo -e "\tSecound argument is optional and can contain the path to where fil"
    exit							# Terminate script
fi

NROFHOSTS=0							# Total number of hosts (lines) in CSV file
NROFERRORS=0						# Nr of hosts in CSV file without address or hostname
OLDIFS=$IFS							# Store away seperator
IFS=","								# Seperator for CSV file

if [ -z "$2" ]; then				# Where are files created message
	echo -e "\n\tGenerating hosts from $1 into working directory"
else
	echo -e "\n\tGenerating hosts from $1 into directory $2"
fi

while read address hostname hostgroup generic # Read CSV
	do
		let "NROFHOSTS += 1"		# Counts times in the loop
		if [ -z "$hostname" ]; then	# If there is no hostname defined
			if [ $NROFERRORS -lt 1 ]; then
				echo -e "\n\tHostname and Address are mandatory."
			fi
			echo -e "\tMissing for host on line nr: $NROFHOSTS"
			let "NROFERRORS += 1"	# Counts how many errors

		else						# Else there is a hostname defined
			file=""					# Filename
			if [ -z $2 ]; then		# Add path if supplyed
				file="$2"
			fi

			file+="$hostname"		# Hostname will be name of the file
			file+=".cfg"

			## Echo to file starts ##
			echo "define host {" > "$file"

			if [ -z "$generic" ]; then	# Use default if no generic defined
				echo -e "\tuse\t\t\t$defaultGeneric" >> "$file"
			else					# Else use supplyed
				echo -e "\tuse\t\t\t$generic" >> "$file"
			fi

			echo -e "\taddress\t\t$address" >> "$file"
			echo -e "\thost_name\t$hostname" >> "$file"
			echo -e "\talias\t\t$hostname" >> "$file"

			if [ -z "$hostgroup" ]; then	# Use default if no hostgroup supplyed
				echo -e "\thostgroups\t$defaultHostgroup" >> "$file"
			else					# Else use supplyed
				hostgroups=${hostgroup//;/,}	# Replace ; with , for icinga config
				echo -e "\thostgroups\t$hostgroups" >> "$file"
			fi

			echo "}" >> "$file"
			## Echo to file ends ##
		fi
	done < $1

echo -e "\n\tDone"
echo -e "\tSuccessfully created "$((NROFHOSTS - NROFERRORS))" hosts"
echo -e "\t$NROFERRORS hosts where not create because of errors."

IFS=$OLDIFS 					# Set seperator back to old
exit 							# Terminate script
