# diff check_asa_vpn.pl orig/check_asa_sessions.pl
<                 'sessions' => '1.3.6.1.4.1.9.9.392.1.3.1.0',
<                 'maxSessions' => '1.3.6.1.4.1.9.9.392.1.1.1.0' 
---
>                 'sessions' => '.1.3.6.1.4.1.9.9.147.1.2.2.2.1.5.40.6',
109c107
<         my ($sessions, $maxSessions);
---
>         my ($sessions);
120c118
<         my $result = $session->get_request ($snmp_string{sessions}, $snmp_string{maxSessions});
---
>         my $result = $session->get_request ($snmp_string{sessions});
124c122
<         unless (defined ($status{sessions}) && defined ($status{maxSessions})) { 
---
>         unless (defined ($status{sessions})) { 
129c127
<         return ($status{sessions}, $status{maxSessions});
---
>         return ($status{sessions});
137c135
< # Get the status for sessions
---
> # Get the status for the active and standby unit
139,140c137
< my ($sessions, $maxSessions) = &status_request ($hostname, $community, $debug, $timeout, $retries);
< my $percentUse = ceil(($sessions / $maxSessions)*100);
---
> my ($sessions) = &status_request ($hostname, $community, $debug, $timeout, $retries);
142c139
< # Determine status to icinga
---
> # Determine status of cluster
144,145c141,142
< if ($percentUse < $warnning) {
<         print "OK - Cisco ASA VPN sessions: $sessions of $maxSessions used ($percentUse%) | vpn_users=$sessions\n";
---
> if ($sessions < $warnning) {
>         print "OK - Cisco ASA sessions:$sessions\n";
147,148c144,145
< } elsif ($percentUse > $warnning && $percentUse < $critical) {
<         print "Warning - Cisco ASA VPN sessions: $sessions of $maxSessions used ($percentUse%) | vpn_users=$sessions\n";
---
> } elsif ($sessions > $warnning && $sessions < $critical) {
>         print "Warning -Cisco ASA sessions:$sessions\n"; 
151c148
<         print "Critical - Cisco ASA VPN sessions: $sessions of $maxSessions used ($percentUse%) | vpn_users=$sessions\n";
---
>         print "Critical - Cisco ASA sessions:$sessions\n"; 
154c151
<         print "Unknown - Cisco ASA VPN $sessions | vpn_users=$sessions\n";
---
>         print "Unknown - Cisco ASA $sessions\n";
156a154,155

# diff check_iftraffic64.pl orig/check_iftraffic64.pl 
88d87
< my $no_percent;     #added 20130502 by MonKey
119c118
< my $TRAFFIC_FILE = "/var/cache/icinga/traffic/";
---
> my $TRAFFIC_FILE = "/usr/local/nagios/libexec/traffic/";
169,170d167
<         #added 20130502 by MonKey
<         "n|nopercent" => \$no_percent,
350,357c347,350
<                         if($iface_speed == 0) {        # default to 100mbps
<                                 $iface_speed = 100 * 1000 * 1000;
<                         } else {
<                                 # number returned but NOT greater than zero - bad output
<                                 # try 32 bit speed counter
<                                 $iface_speed = $response->{ $snmpIfSpeed32 . "." . $iface_number };                
<                                 debugout ("INTERFACE using 32 bit speed counters: $iface_speed", "2");
<                         }
---
>                         # number returned but NOT greater than zero - bad output
>                         # try 32 bit speed counter
>                         $iface_speed = $response->{ $snmpIfSpeed32 . "." . $iface_number };                
>                         debugout ("INTERFACE using 32 bit speed counters: $iface_speed", "2");
449a443
> 
469,480d462
< # Added by MonKey, 2013
< # Lets us use absolute numbers (in mbps) instead of percentages
< my $in_test;
< my $out_test;
< if($no_percent) {
<         $in_test = $in_ave / (1000*1000);
<         $out_test = $out_ave / (1000*1000);
< } else {
<         $in_test = $in_ave_pct;
<         $out_test = $out_ave_pct;
< }
< 
505d486
< 
507c488
< if ( ( $in_test > $crit_usage ) or ( $out_test > $crit_usage ) or ( $if_status != 1 ) ) {
---
> if ( ( $in_ave_pct > $crit_usage ) or ( $out_ave_pct > $crit_usage ) or ( $if_status != 1 ) ) {
511c492,493
< if (   (( $in_test > $warn_usage ) or ( $out_test > $warn_usage )) && $state eq "OK" )
---
> if (   ( $in_ave_pct > $warn_usage )
>         or ( $out_ave_pct > $warn_usage ) && $state eq "OK" )
625c607
<                          print "Interface $ifdescr = $snmpkey ";  #debug
---
>                          print "$ifdescr = $key / $snmpkey \n";  #debug
747c729
<     Usage: check_iftraffic64.pl -H host [ -C community_string ] [ -i if_index|if_descr ] [ -r ] [ -b if_max_speed_in | -I if_max_speed_in ] [ -O if_max_speed_out ] [ -n ] [ -u ] [ -B ] [ -A IP Address ] [ -L ] [ -M ] [ -w warn ] [ -c crit ]
---
>     Usage: check_iftraffic64.pl -H host [ -C community_string ] [ -i if_index|if_descr ] [ -r ] [ -b if_max_speed_in | -I if_max_speed_in ] [ -O if_max_speed_out ] [ -u ] [ -B ] [ -A IP Address ] [ -L ] [ -M ] [ -w warn ] [ -c crit ]
784,785d765
<         -n --nopercent FLAG
<         Sets the thresholds to be in mbps instead of percent

#diff check_netbotz.py orig/check_netbotz.py 

<     parser.add_option("-t", "--type", dest="type", default="temp", type="string", help="Test Type. Valid values are 'temp' for temprature test, and 'humid' for humidity tests. [Default:temp]")
---
>     parser.add_option("-t", "--type", dest="type", default="temp", type="string", help="Test Type. Valid values are 'temp' for tempratue test, and 'humid' for humidity tests. [Default:temp]")
65,69c65
<     parser.add_option("--warning_low", dest="warn_l", type="int", help="The low warning threshold")
<     parser.add_option("--critical_low", dest="crit_l", type="int", help="The low critical threshold")
<     parser.add_option("--warning_high", dest="warn_h", type="int", help="The high warning threshold")
<     parser.add_option("--critical_high", dest="crit_h", type="int", help="The high critical threshold")
<  
---
>     
72a69
>     
76,80c73
<     
<     if options.warn_l == None or options.crit_l == None or options.warn_h == None or options.crit_h == None:
<                 print "Error: high and low warning and critical thresholds must be supplied."
<                 sys.exit(RET_CODES["UNKNOWN"])
<     
---
>         
105c98
<         test_name = "Temperature"
---
>         test_name = "Tempratue"
160a154
>     
162d155
<         sensor_val = int(return_values[key]["value"])
164,172c157,158
<         if sensor_val < options.crit_l:
<             ret_code = RET_CODES["CRITICAL"]
<             desc += " - The %s value is LOWER than allowed treshold. " % test_name
<         elif sensor_val > options.crit_h:
<             ret_code = RET_CODES["CRITICAL"] 
<             desc += " - The %s value is HIGHER than allowed treshold. " % test_name        
<         elif sensor_val < options.warn_l:
<             if ret_code == RET_CODES["OK"]:
<                 ret_code = RET_CODES["WARNING"] 
---
>         if return_values[key]["value"] < return_values[key]["low_value"]:
>             ret_code = on_error_retcode
174,179c160,164
<         elif sensor_val > options.warn_h:
<             if ret_code == RET_CODES["OK"]:
<                ret_code = RET_CODES["WARNING"] 
<             desc += " - The %s value is HIGHER than allowed treshold. " % test_name        
<         else:
<             desc += " - The %s value is OK. " % test_name
---
>         elif return_values[key]["value"] > return_values[key]["high_value"]:
>             ret_code = on_error_retcode
>             desc += " - The %s value is HIGHER than allowed treshold. " % test_name
>         
>         desc += " - The %s value is OK. " % test_name
185,186d169
<     elif ret_code == RET_CODES["WARNING"]:
<         desc = "WARNING: "+desc
188c171
<         desc = "CRITICAL: "+desc
---
>         desc = "ERROR: "+desc
192,193c175
<         sensor_name = return_values[key]["name"].replace(" ", "_")
<         desc += "'%s_%s'=%s%s;;;%s;%s; " % (sensor_name,
---
>         desc += "'%s %s'=%s%s;;;%s;%s; " % (return_values[key]["name"],
198a181
>  


#diff check_ndbd.pl orig/check_ndbd.pl 

< my $check_command = '/usr/sbin/ndb_mgm';
---
> my $command_prefix = '/opt/mysql/bin/';
> my $check_command = 'ndb_mgm';
40d40
< my $host=undef;
44,45c44
< GetOptions(                "check_command=s"                 => \$check_command,
<                         "host=s"                => \$host,
---
> GetOptions(        "check_command=s"                 => \$check_command,
88c87
<                 print "OK - Acceptable number of nodes connected. | mgm_nodes=$mgm_value ndb_nodes=$ndb_value sql_nodes=$sql_value\n";
---
>                 print "OK - Acceptable number of nodes connected.\n";
104c103
<         open(NS, $check_command. " " . $host ." -e $check_expression |") || die "Command failed! Check the script cause it sucks...\n";
---
>         open(NS, $command_prefix.$check_command." -e $check_expression |") || die "Command failed! Check the script cause it sucks...\n";
138c137
<         open(NS, $check_command . " " . $host ." -e $check_expression |") || die "Command failed!  Is your path (prefix) correct?\n";
---
>         open(NS, $command_prefix.$check_command." -e $check_expression |") || die "Command failed!  Is your path (prefix) correct?\n";




< $np->add_arg(
<   spec => 'interval|i=s',
<   help => "-i, --interval=<seconds>\n"
<     . '   Interval in seconds between 1st and last xml sample',
<   required => 0,
< );
< 
229d220
< my $interval = $np->opts->interval;
233c224
< $debug_timeshift = (!$interval) ? 10 : $interval;
---
> $debug_timeshift = 10;
341,342d331
< 
< 
346c335
<         my $perf;
---
>     my $perf = {};
348,354c337
<         if ($command eq 'CPU' or 'MEM' and defined($subcommand)) {
<         if (uc($subcommand) eq "USAGE") {
<                          return $rrd;
<                 }
<         }
< 
<         # get newest perf data
---
>     # get newest perf data
356,357c339,340
<                 if ($time < $row->{timestamp}) {
<                 $time = $row->{timestamp};
---
>         if ($time < $row->{timestamp}) {
>             $time = $row->{timestamp};
361,362c344
<         return $perf;
<         
---
>     return $perf;
373,374c355,356
<         my $timestamp = parse_datetime_iso8601($host->get_servertime()) - $debug_timeshift;
<         return get_latest_perfdata($host, $timestamp);
---
>     my $timestamp = parse_datetime_iso8601($host->get_servertime()) - $debug_timeshift;
>     return get_latest_perfdata($host, $timestamp);
386c368
<            my $timestamp = parse_datetime_iso8601($host->get_servertime()) - $debug_timeshift;
---
>     my $timestamp = parse_datetime_iso8601($host->get_servertime()) - $debug_timeshift;
486c468,469
<         my $usage = 0;
---
>     my $perf = $uuid ? get_latest_host_by_uuid_perfdata($xen, $hostname) : get_latest_host_by_name_perfdata($xen, $hostname);
>     my $usage = 0;
491c474
<         my $perf = $uuid ? get_latest_host_by_uuid_perfdata($xen, $hostname) : get_latest_host_by_name_perfdata($xen, $hostname);
---
> 
494,499c477,482
<                         foreach my $row (@{$perf}) {
<                           $usage += $row->{data}->{cpu_avg}->{$rolluptype};
<                           $i++;
<                         }
<                         $usage = $usage / $i;
<                         $usage = simplify_number($usage * 100);
---
>             # get all cpu values with keys: cpu0, cpu1, ..., cpu7, ...
>             while (my $val = $perf->{"cpu$i"}) {
>                 $usage += $val->{$rolluptype};
>                 $i++;
>             }
>             $usage = simplify_number($usage / $i * 100) if ($i > 0);
535c518
<     my $usage = 0;
---
>     my $usage = 'nan';
542d524
<         my $i = 0;
543a526
> 
546,558c529,532
<                         my $allocatedMem = 0;
<                         foreach my $row (@{$perf}) {
<               $allocatedMem = $row->{data}->{memory_total_kib}->{$rolluptype};
<                           my $tempUsage = $allocatedMem - $row->{data}->{memory_free_kib}->{$rolluptype};
<                           $usage += $tempUsage;
<                           $i++;
<             }
<                         $usage = $usage / $i;
<                         my $percentUsage = int($usage / $allocatedMem * 100);
<             my $mbusage = simplify_number($usage / 1024);
<             $output = "mem: usage = " . $mbusage . " MB (" . $percentUsage . "%)";
<             $np->add_perfdata(label => "used", value => perfvalue($mbusage), uom => 'MB', threshold => $np->threshold);
<             $res = $np->check_threshold(check => $percentUsage);
---
>             $usage = simplify_number($perf->{memory_total_kib}->{$rolluptype} / 1024) if (exists($perf->{memory_total_kib}));
>             $output = "mem: usage = " . $usage . " MB";
>             $np->add_perfdata(label => "used", value => perfvalue($usage), uom => 'MB', threshold => $np->threshold);
>             $res = $np->check_threshold(check => $usage);
624c598
<                 $send += $value->{tx} / 1024 if (exists($value->{tx}));
---
>         $send += $value->{tx} / 1024 if (exists($value->{tx}));
758c732
<                         $localtime_diff = time() - parse_datetime_iso8601($host->get_server_localtime());
---
>         $localtime_diff = time() - parse_datetime_iso8601($host->get_server_localtime());


# diff metricinga.py orig/metricinga.py

< import MySQLdb
<     PERFDATA TIL DATABASE
<     if len(check_result['SERVICEPERFDATA'])!= 0:
<         conn = MySQLdb.connect (host = "localhost",
<                              user = "root",
<                              passwd = "Bachel0r",
<                              db = "perfdata")
< 
<         cursor = conn.cursor ()
< 
<         cursor.execute( 'INSERT INTO servicedata(TIMET,HOSTNAME,SERVICEDESC, SERVICEPERFDATA) values("%s","%s","%s","%s")' % (check_result['TIMET'],check_result['HOSTNAME'],check_result['SERVICEDESC'],check_result['SERVICEPERFDATA']) )
