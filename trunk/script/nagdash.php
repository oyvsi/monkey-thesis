<?php
require_once 'config.php';
error_reporting(!E_NOTICE);

// For authenticating agains Icinga Classic
$context = stream_context_create(array(
    'http' => array(
    'header'  => "Authorization: Basic " . base64_encode("$classic_username:$classic_password")
    )
));

// Definitions for nagios states 
$nagios_host_status = array(0 => "UP", 1 => "DOWN", 2 => "UNREACHABLE");
$nagios_service_status = array(0 => "OK", 1 => "WARNING", 2 => "CRITICAL", 3 => "UNKNOWN");

// Definitions for nagios states to css-classes
$nagios_host_status_colour = array(0 => "status_green", 1 => "status_red", 2 => "status_yellow");
$nagios_service_status_colour = array(0 => "status_green", 1 => "status_yellow", 2 => "status_red", 3 => "status_grey");

// Host-query part for url used in retreiving data from icinga-web API, all hosts which are down or unreachable
$hostQuery = "filter[OR(HOST_CURRENT_STATE|=|1;HOST_CURRENT_STATE|=|2)]/
				  columns[HOST_ID|HOST_CURRENT_CHECK_ATTEMPT|HOST_OUTPUT|HOST_NAME|HOST_LAST_STATE_CHANGE|HOST_CURRENT_STATE|HOST_PROBLEM_HAS_BEEN_ACKNOWLEDGED|
							 HOST_SCHEDULED_DOWNTIME_DEPTH|HOST_NOTIFICATIONS_ENABLED|HOST_MAX_CHECK_ATTEMPTS]/
				  order(HOST_CURRENT_STATE;DESC)/
				  countColumn=HOST_ID/
				  authkey=$APIkey/json";

// Service-query, all services in critical or warning state and host is UP (0)
$serviceQuery = "filter[AND(HOST_CURRENT_STATE|=|0;OR(SERVICE_CURRENT_STATE|=|1;SERVICE_CURRENT_STATE|=|2))]/
					  columns[SERVICE_ID|HOST_SCHEDULED_DOWNTIME_DEPTH|SERVICE_OUTPUT|SERVICE_NOTIFICATIONS_ENABLED|SERVICE_SCHEDULED_DOWNTIME_DEPTH|
								 SERVICE_PROBLEM_HAS_BEEN_ACKNOWLEDGED|SERVICE_NAME|HOST_NAME|SERVICE_CURRENT_STATE|HOST_NAME|HOST_CURRENT_STATE|SERVICE_LAST_STATE_CHANGE|
								 SERVICE_MAX_CHECK_ATTEMPTS|SERVICE_CURRENT_CHECK_ATTEMPT]/
					  order(SERVICE_CURRENT_STATE;DESC)/
					  countColumn=SERVICE_ID/
					  authkey=$APIkey/json";

// Totals queries 
$hostTotalQuery = "filter/columns[HOST_CURRENT_STATE]/countColumn=HOST_ID/authkey=$APIkey/json";
$serviceTotalQuery = "filter/columns[SERVICE_CURRENT_STATE]/countColumn=SERVICE_ID/authkey=$APIkey/json";

$hostPriority = array();
$servicePriority = array ();

$hostArray=array();
$serviceArray=array();

// Totals for hosts and services in each state
$host_summary = array();
$service_summary = array();

$known_hosts = array();
$known_services = array();
// Holds services and hosts in warning or critical state, that are not acknowledged
$down_hosts = array();
$broken_services = array();

// Run query against Icinga web API on specified APIhost
function fetchStatus($APIhost,$target, $query) {
	$query = preg_replace('/(\s)+/', '', trim($query)); // Remove whitespace
	$statusDecoded = json_decode(file_get_contents("http://$APIhost/icinga-web/web/api/{$target}/$query"));
   if(!$statusDecoded) { 
		die("<div class='status_red'>Error with $target query </div>");
	}
	if($statusDecoded->success !== 'true') 
		die("<div class='status_red'>{$statusDecoded->errors[0]}</div>");

	$vars = get_object_vars($statusDecoded);

	return($vars);
}
	
$hosts = fetchStatus($APIhost, "host", $hostTotalQuery);
$services = fetchStatus($APIhost, "service", $serviceTotalQuery);

$hostArray = fetchStatus($APIhost, "host", $hostQuery);
$serviceArray = fetchStatus($APIhost, "service", $serviceQuery);

foreach($hosts['result'] as $host) {
	$host_summary[$host->{'HOST_CURRENT_STATE'}] += 1;
}

foreach($services['result'] as $service) {
	$service_summary[$service->{'SERVICE_CURRENT_STATE'}] += 1;
}

// Used in sorting of hosts, based on state and priority variable
function hostCompare($x, $y) {
	//Unreachable is placed after Critical (1 supersedes 2)
	if($x['state'] != 1 && $y['state'] == 1) return 1;
	
	//If both is down, place the one with highest priority first
	if($x['state'] == 1 && $y['state'] == 1) 
		return ($x['priority'] < $y['priority']) ? 1 : -1;
}

//  Used in sorting of services, based on state and priority variable
function serviceCompare($x, $y) {
	// Critical (2) before Warning (1)
	if ($x['state'] < $y['state']) return 1;
	
	// If both is Critical, place the one with highest priorty first
	if($x['state'] == 2 && $y['state'] == 2)
		return ($x['priority'] < $y['priority']) ? 1 : -1;
}

// Loop and check if host is ack'd or not, then populate given array 

foreach($hostArray["result"] as $host_details) {
	$host_attributes = get_object_vars($host_details);
	if (($host_attributes['HOST_PROBLEM_HAS_BEEN_ACKNOWLEDGED'] > 0) || ($host_attributes['HOST_SCHEDULED_DOWNTIME_DEPTH'] > 0) || ($host_attributes['HOST_NOTIFICATIONS_ENABLED'] == 0) ) {
		$array_name = "known_hosts";
	} else {
		$array_name = "down_hosts";
	}
   $hostPriorityQuery = 'filter[AND(OR(HOST_ID|=|' . $host_attributes['HOST_ID'] . ');HOST_CUSTOMVARIABLE_NAME|=|PRIORITY)]/columns[HOST_ID|HOST_NAME|HOST_CUSTOMVARIABLE_VALUE]/order(HOST_CURRENT_STATE;DESC)/countColumn=HOST_ID/authkey=' . $APIkey . '/json';
	
	$priorityResult = fetchStatus($APIhost, 'host', $hostPriorityQuery);
	$priority = get_object_vars($priorityResult['result'][0]);
	// Populate either known_hosts or down_hosts array with key => value 
	array_push($$array_name, array(
		"priority" => (isset($priority)) ? $priority['HOST_CUSTOMVARIABLE_VALUE'] : 0,
		"hostname" => $host_attributes['HOST_NAME'],
		"state" => $host_attributes['HOST_CURRENT_STATE'],
		"duration" => $host_attributes['HOST_LAST_STATE_CHANGE'],
		"detail" => $host_attributes['HOST_OUTPUT'],
		"current_attempt" => $host_attributes['HOST_CURRENT_CHECK_ATTEMPT'],
		"max_attempts" => $host_attributes['HOST_MAX_CHECK_ATTEMPTS'],
		"is_hard" => ($host_attributes['HOST_CURRENT_CHECK_ATTEMPTS'] >= $host_attributes['HOST_MAX_CHECK_ATTEMPTS']) ? true : false,
		"is_downtime" => ($host_attributes['HOST_SCHEDULED_DOWNTIME_DEPTH'] > 0) ? true : false,
		"is_ack" => ($host_attributes['HOST_PROBLEM_HAS_BEEN_ACKNOWLEDGED'] > 0) ? true : false,
		"is_enabled" => ($host_attributes['HOST_NOTIFICATIONS_ENABLED'] > 0) ? true : false,
	)); 
}

// Loop and check if service is ack'd or not, then populate given array
foreach($serviceArray['result'] as $service_detail) {
	$service_attributes = get_object_vars($service_detail);
	$servicePriorityQuery = 'filter[AND(OR(SERVICE_ID|=|' . $service_attributes['SERVICE_ID'] . 
									');SERVICE_CUSTOMVARIABLE_NAME|=|PRIORITY)]/
									columns[SERVICE_ID|SERVICE_CUSTOMVARIABLE_VALUE]/order(SERVICE_CURRENT_STATE;DESC)/authkey=' . $APIkey . '/json';
	$priorityResult = fetchStatus($APIhost, 'service', $servicePriorityQuery);
	$priority = get_object_vars($priorityResult['result'][0]);

	//if the host is OK, AND the service is NOT OK. 
	// Sort the service into the correct array. It's either a known issue or not. 
	if ( ($service_attributes['SERVICE_PROBLEM_HAS_BEEN_ACKNOWLEDGED'] > 0) || ($service_attributes['SERVICE_SCHEDULED_DOWNTIME_DEPTH'] > 0) || ( $service_attributes['SERVICE_NOTIFICATIONS_ENABLED'] == 0 ) || ($service_attributes['HOST_SCHEDULED_DOWNTIME_DEPTH'] > 0) ) {
		 $array_name = "known_services";
	} else {
		 $array_name = "broken_services";
	}

	// Populate either known_services or broken_hosts array with key => value
	array_push($$array_name, array(
		"priority" => (isset($priority)) ? $priority['SERVICE_CUSTOMVARIABLE_VALUE'] : 0,
		"hostname" => $service_attributes['HOST_NAME'],
	   "service_name" => $service_attributes['SERVICE_NAME'],
		"state" => $service_attributes['SERVICE_CURRENT_STATE'],
		"duration" => $service_attributes['SERVICE_LAST_STATE_CHANGE'],
	   "detail" => $service_attributes['SERVICE_OUTPUT'],
		"current_attempt" => $service_attributes['SERVICE_CURRENT_CHECK_ATTEMPT'],
		"max_attempts" => $service_attributes['SERVICE_MAX_CHECK_ATTEMPTS'],
		"is_hard" => ($service_attributes['SERVICE_CURRENT_CHECK_ATTEMPT'] >= $service_attributes['SERVICE_MAX_CHECK_ATTEMPTS']) ? true : false,
		"is_downtime" => ($service_attributes['SERVICE_SCHEDULED_DOWNTIME_DEPTH|'] > 0) ? true : false,
		"is_ack" => ($service_attributes['SERVICE_PROBLEM_HAS_BEEN_ACKNOWLEDGED'] > 0) ? true : false,
		"is_enabled" => ($service_attributes['SERVICE_NOTIFICATIONS_ENABLED'] > 0) ? true : false,
	));
} 
?>

<div id="host_section">
	<div id="frame">
		<div class="section">
			<p class="totals">
				<span class="section_title">Hosts</span>
				<span class="total_count">
				<?php foreach($host_summary as $state => $count) { 
					echo "<span class='{$nagios_host_status_colour[$state]}'>{$count}</span> "; } ?>
				</span>
			</p>
	<?php 
			if (count($down_hosts) > 0): 
				uasort($down_hosts, 'hostCompare');
			?>
			<table id="broken_hosts" class="widetable">
			<tr><th>Hostname</th><!--<th>Pri</th>--><th width="150px">State</th><th>Since</th><!--<th>Attempt</th>--><th>Detail</th></tr>
	<?php	foreach($down_hosts as $host) {
				echo "<tr id='host_row' class='{$nagios_host_status_colour[$host['state']]}'>";
				echo "<td>{$host['hostname']}</td>";
				//	echo "<td>{$host['priority']}</td>";
				echo "<td>{$nagios_host_status[$host['state']]}</td>"; 
				echo "<td>{$host['duration']}</td>";
			 	//echo "<td>{$host['current_attempt']}/{$host['max_attempts']}</td>";
				echo "<td class=\"desc\">{$host['detail']}</td>";
				echo "</tr>";
			}
	 		?>
			</table>
		<?php 
			else: 
		?> 
			<table class='widetable status_green'><tr><td><b>All hosts OK</b></td></tr></table>
		<?php 
			endif; 			
		
		if (count($known_hosts) > 0): ?>
			<div class='known_problems' id='known_host_probems'>
				<p class='totals'><span class='known_section_title'>Known Host Problems</span></p>
	  			<table class='widetable known_hosts'>
		 			<th>Hostname</th><th>State</th><th>Since</th><th>Detail</th></tr>
			<?php foreach($known_hosts as $this_host) {
				 		$status_text = false;
				 		if ($this_host['is_ack']) $status_text = "ack";
				 		if ($this_host['is_downtime']) $status_text = "downtime";
				 		if (!$this_host['is_enabled']) $status_text = "disabled";
				 		echo "<tr id='host_row' class='{$nagios_host_status_colour[$this_host['state']]}'>";
				 		echo "<td>{$this_host['hostname']}</td>";
				 		echo "<td>{$nagios_host_status[$this_host['state']]} " . ($status_text ? "($status_text)" : "") . "</td>";
				 		echo "<td>{$this_host['duration']}</td>";
				 		echo "<td class=\"desc\">{$this_host['detail']}</td>";
				 		echo "</tr>";
		  		}
		 ?> 
		 		</table>
			</div><!-- known_problems end-->
	<?php endif; ?>
		</div> <!-- section end -->
	</div> <!-- frame end -->
</div> <!-- host_section end -->

<div id="service_section">
	<div id="frame">
		<div class="section">
			<p class="totals">
				<span class="section_title">Services</span>
				<span class="total_count">
				<?php foreach($service_summary as $state => $count) { 
					echo "<span class='{$nagios_service_status_colour[$state]}'>{$count}</span> "; 
				} ?>
				</span>
			</p>

	<?php if (count($broken_services) > 0): uasort($broken_services, 'serviceCompare');
	?>
			<table class="widetable" id="broken_services">
			<tr><th width="20%">Hostname</th><!--<th>Pri</th>--><th width="50%">Service</th><th width="15%">State</th><th width="15%">Since</th><!--<th width="5%">Attempt</th>--></tr>
	<?php	foreach($broken_services as $service) {
				if ($service['is_hard']) { $soft_tag = ""; } else { $soft_tag = "(soft)"; }
					echo "<tr class='{$nagios_service_status_colour[$service['state']]}'>";
					echo "<td>{$service['hostname']}</td>";
//					echo "<td>{$service['priority']}</td>";
					echo "<td>{$service['service_name']} - {$service['detail']}</td>";
					echo "<td>{$nagios_service_status[$service['state']]} {$soft_tag}</td>";
					echo "<td>{$service['duration']}</td>";
					//echo "<td>{$service['current_attempt']}/{$service['max_attempts']}</td>";
					echo "</tr>";
			 }
	?>
			</table>
	<?php	else: ?>
			<table class="widetable status_green"><tr><td><b>All services OK</b></td></tr></table>
	<?php endif;
			if (count($known_services) > 0): ?>
			<div class="known_problems" id="known_service_problems">
				<p class="totals"><span class="known_section_title">Known Service Problems</span></p>
				<table class="widetable" id="known_services">
				<tr><th width="30%">Hostname</th><th width="37%">Service</th><th width="18%">State</th><th width="10%">Since</th><!--<th width="5%">Attempt</th>--></tr>
	<?php		foreach($known_services as $service) {
					if ($service['is_ack']) $status_text = "ack";
	  		 	   if ($service['is_downtime']) $status_text = "downtime";
			  	   if (!$service['is_enabled']) $status_text = "disabled";
					echo "<tr class='{$nagios_service_status_colour[$service['state']]}'>";
		  		   echo "<td>{$service['hostname']}</td>";
	        	   echo "<td>{$service['service_name']}</td>";
			      echo "<td>{$nagios_service_status[$service['state']]} ({$status_text})</td>";
		         echo "<td>{$service['duration']}</td>";
				   //echo "<td>{$service['current_attempt']}/{$service['max_attempts']}</td>";
				   echo "</tr>";
			   }
	 ?>
                                        
				</table>
			</div>
	<?php endif; ?>
		</div>
	</div>
</div>
