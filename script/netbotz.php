<?php
/*
 * Contacts Icinga web API and serves data from services 
 * Check Netbotz Humid and Check Netbotz Temp as json data
 * Author Monkey, 2013
 */

require_once 'config.php';

// Queries Icinga API and return array of sensor values of set type
function check_sensor($query, $type, $dummydata) {
	// Serve dummy data if we are in test
	if($dummydata) {
		return array(array('name' => 1, 'data' => 19), array('name' => 2, 'data' => 18), array('name' => 4, 'data' => 23), array('name' => 5, 'data' => 24), array('name' => 3, 'data' => 24)); 
	}
	// Query the API	
	$result = json_decode(file_get_contents($query));
	$result_obj = $result->result[0];
	// Get value for each sensor
	// Data looks like: 'Sensor_MM:1_Humidity'=16%;;;99;0;_'Sensor_MM:2_Humidity'=15%;;;99;0;_'Sensor_MM:5_Humidity'=15%;;;99;0;_'Sensor_MM:4_Humidity'=15%;;;99;0;_  
	preg_match_all('/Sensor_MM:(\d+)_' . $type . '\'=(\d+)|{%};/', $result_obj->SERVICE_PERFDATA, $matches);
	$result = array();

	for($i = 0; $i < count($matches[1]); $i++) {
		$sensor = array();
		$sensor['name'] = $matches[1][$i];
		$sensor['data'] = $matches[2][$i];
		
		array_push($result, $sensor);
	}
	return $result;
}

if(isset($_GET['type'])) {
	$query = $type = null;
	if($_GET['type'] == 'Temperature') {
			$query = 'http://' . $APIhost . '/icinga-web/web/api/service/filter[(SERVICE_NAME%7C=%7CCheck%20Netbotz%20Temp)]/countColumn=SERVICE_ID/authkey=' . $APIkey . '/json';
			echo json_encode(check_sensor($query, 'Temperature', $dummydata), JSON_NUMERIC_CHECK);
	} 
	elseif ($_GET['type'] == 'Humidity') {
		$query = 'http://' . $APIhost . '/icinga-web/web/api/service/filter[(SERVICE_NAME%7C=%7CCheck%20Netbotz%20Humid)]/countColumn=SERVICE_ID/authkey=' . $APIkey . '/json';
		echo json_encode(check_sensor($query, 'Humidity', $dummydata), JSON_NUMERIC_CHECK);
	}
}
