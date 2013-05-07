#! /usr/bin/env perl
# Script to sync Active Directory entries to Icinga contacts
#
# Note maxValRange by default is 5k in 2k8, 10k in 2k3, meaning the max number of entries returned
# this is OK for our implementation
# 
# If the option gen_service is set a generic service for each contact group is generated, but only 
# if it does not already exist.
#
# MonKey 2013

use warnings;
use strict;

use Getopt::Long;
use Net::LDAP;
use File::Copy;
use constant {
    LDAP_URL => "host.example.org",
    LDAP_PORT => 3268,
    LDAP_SCHEME => "ldap",
    BIND_DN => "CN=icinga,OU=Serviceaccounts,DC=example,DC=org",
    BIND_PASSWD => "icinga_pwd",
    BASE_USER_DN => "OU=Users,DC=example,DC=org",
    BASE_GROUP_DN => "OU=icinga_contacts,DC=example,DC=org",
    ALL_CONTACTS_GROUP => "CN=all_icinga_contacts,OU=icinga_contacts,DC=example,DC=org",
};

my $gen_service = 0;
my $exit_status = 0;
my $ldap = Net::LDAP->new(LDAP_URL, port => LDAP_PORT, scheme => LDAP_SCHEME) or die "Unable to connect to ldap server $@";
my $bind = $ldap->bind(BIND_DN, password => BIND_PASSWD); 

# Find out if we should generate generic service with the contactgroups
GetOptions("gen_service" => \$gen_service);

# If we can't bind to AD, theres no point in going further
if($bind->code != 0) {
	die "Unable to bind to LDAP: " . $bind->error_desc;
}

# First we need to get all contacts
my @contact_entries = group_members(ALL_CONTACTS_GROUP);
my @contacts;

# Write the contacts
foreach my $entry (@contact_entries) {
	my %contact = contact($entry);
	push(@contacts, %contact);
	write_contact(%contact);
}

# Now we can do the groups. Query for all of them
my $groups = $ldap->search(filter => "objectClass=group",
			   base	  => BASE_GROUP_DN,
               attrs  => "cn");
$groups->code && die $groups->error;

# Write all groups
foreach my $group($groups->entries) {
	my %contactgroup = contactgroup($group);
	write_contactgroup(%contactgroup);
	if($gen_service) {
		write_gen_service(%contactgroup);
	}
}

# Done. Exit with code 2 if we have warnings
exit $exit_status;

# Gets all group members of a group with passed DN recursively, i.e., descend into children groups 
# Returns an array of NET::LDAP::Entry objects 
sub group_members {
	my $DN = $_[0];
	my $results = $ldap->search(filter => "(&(memberOf:1.2.840.113556.1.4.1941:=$DN)(objectClass=user)(objectCategory=person))",
			    	    base   => BASE_USER_DN,
                            	    attrs  => "mail", "sAMAccountName");
	#print $results->count();
	$results->code && die $results->error;
	return $results->entries;
}

# Gets relevant information for a contact from a passed NET::LDAP::Entry object
# Returns an asociative array
sub contact {
	my $entry = $_[0];
	my %contact;

	$contact{'sAMAccountName'} = $entry->get_value('sAMAccountName');
	$contact{'cn'} = $entry->get_value('cn');
	$contact{'mobile'} = $entry->get_value('mobile');
	$contact{'mail'} = $entry->get_value('mail');

	if(!defined $contact{'mobile'}) {
		warn "Mobile is not set for $contact{'cn'}";
		$contact{'mobile'} = '';
		$exit_status = 2 if $exit_status == 0;
	} 	
	if(!defined $contact{'mail'}) {
		warn "Mail is not set for $contact{'cn'}";
		$contact{'mail'} = '';
		$exit_status = 2 if $exit_status == 0;
	}
	
	return %contact;
}

# Gets relevant information for a contactgroup from a passwd NET::LDAP::Entry object
# Returns an asociative array
sub contactgroup {
	my $group = $_[0];
	my @member_list = group_members($group->get_value('distinguishedName'));

	my @members;
	my %contactgroup;

	foreach my $member(@member_list) {
		push(@members, $member->get_value('sAMAccountName'));
	}
	
	$contactgroup{'members'} = join(',', @members);
	$contactgroup{'sAMAccountName'} = $group->get_value('cn');
	$contactgroup{'cn'} = $group->get_value('cn');

	return %contactgroup;
}

# Writes a contact to file
# Takes an associative array with information as parameter
sub write_contact {
	my %contact = @_;
	my $file_name = "/etc/icinga/objects/contacts/$contact{'sAMAccountName'}_contact.cfg";

	my $data =  "define contact {
		contact_name    $contact{'sAMAccountName'}    ; AD account
		use             generic_contact
		alias           $contact{'cn'}    ; Full name of user
		email           $contact{'mail'}
		pager		$contact{'mobile'}
	}";

	write_config_file($file_name, $data);
}

# Writes a contactgroup to file
# Takes an associative array with information as parameter
sub write_contactgroup {
	my %contactgroup = @_;
	my $file_name = "/etc/icinga/objects/contactgroups/$contactgroup{'sAMAccountName'}_contactgroup.cfg";

	my $data = "define contactgroup {
		contactgroup_name	$contactgroup{'sAMAccountName'}
		alias			$contactgroup{'cn'}
		members			$contactgroup{'members'}	
	}";
	
	write_config_file($file_name, $data);
}

# Writes a generic service for a contact group if one does not already exist
sub write_gen_service {
	my %contactgroup = @_;
	my $file_name = "/etc/icinga/objects/generics/services/$contactgroup{'sAMAccountName'}.cfg";
	
	unless (-e $file_name) {
		my $data = "# Generated generic from sync. This file will not be overwritten and can be used as a template for services where you want this contactgroup notified.
		define service {
			use				 generic_service
			name             $contactgroup{'sAMAccountName'}               
			contact_groups   $contactgroup{'sAMAccountName'}          
			register                        0      
		}";
		open(my $fh, '>', $file_name) or die "Could not open file $file_name: $!";
    	print $fh $data;
    	close $fh;	
	}
}

# Writes a config file
# Checks if the config is valid, and rolls back if a config file with the same name existed before
# Note that no files will be written if there's already an error with the icinga config
#
# Parameters are:
# 0: The full path to the file to be written
# 1: The data to be written to the file
sub write_config_file {
	my $file_name = $_[0];
	my $data = $_[1];
	my $rollback = 0;
	
	# If config file already exists, take a backup so we can roll back on error
	if(-e $file_name) {
		copy($file_name, "${file_name}_bak") or die "Could not copy $file_name for backup: $!";	
		$rollback = 1;
	}

	# Write new config file
	open(my $fh, '>', $file_name) or die "Could not open file $file_name: $!";	
	print $fh $data;
	close $fh;

	# Check config
	my @check = `icinga -v "/etc/icinga/icinga.cfg"`;

	# Exit status was not success
	if($? != 0) {
		unlink $file_name or die "Could not delete $file_name: $!"; # Remove our config file
		print "\nError in processing contact $file_name: \n";
		for(@check) {
			$exit_status = 1;
			print if(/^Error:/);
		}

		# Copy back our backup if we have one
		if($rollback) {
			copy("${file_name}_bak", $file_name) or die "Could not restore backup file $file_name: $!";
			print "Restored previous version of $file_name \n";
		}
	}

	# Remove our backup file
	if($rollback) {
		unlink("${file_name}_bak") or die "Could not delete backup file $file_name: $!";
	}
}
