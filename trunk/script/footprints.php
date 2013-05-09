<?php

/**
 * Get statistics from footprints database and serve as json 
 *
 * Author: MonKey, 2013
 * Last edited: 24.04.2013
 */

require_once 'db_config.php';   
require_once 'config.php';

// Setup connection to database and SELECT Footprints if we are in production
if(!$dummydata) {
	mssql_connect($servername,$dbusername,$dbpassword) or die("Unable to connect to server");
	mssql_select_db("Footprints");
}

// Queries Footprints and returns the result as key => value
function fetchAmount($dummydata, $query, $type) {
	if($dummydata) {
		return array($type => rand(0,90));
    }
	
	$result = mssql_query($query);
	$amount = mssql_fetch_assoc($result);

   return array($type => $amount['computed']);
}
 
if(isset($_GET['type'])) {
	if($_GET['type'] == 'Graph') {
			$resultArray = array();
			//Submitted and closed today
			$closedQuery = "SELECT COUNT(mrID) FROM dbo.MASTER2 WHERE DATEDIFF(day, mrSUBMITDATE, GETDATE()) = 0 AND mrSTATUS = 'Closed'";
			//Received today
			$receivedQuery = "SELECT COUNT(mrID) FROM dbo.MASTER2 WHERE DATEDIFF(day, mrSUBMITDATE, GETDATE()) = 0";
			//Open overall
			$openQuery = "SELECT COUNT(mrID) FROM dbo.MASTER2 WHERE mrSTATUS != 'Closed' AND mrSTATUS != '_SOLVED_' AND mrSTATUS != '_DELETED_'";
			//Submitted overall, closed today
			$closedAllQuery = "SELECT COUNT(mrID) FROM dbo.MASTER2 WHERE DATEDIFF(day, mrUPDATEDATE, GETDATE()) = 0 AND  mrSTATUS = 'Closed'";
			
			//Merge the results from each query for json-dump
			$resultArray = array_merge(fetchAmount($dummydata, $closedQuery, 'Closed'), fetchAmount($dummydata, $receivedQuery, 'Received'),
												fetchAmount($dummydata, $closedAllQuery, 'ClosedAll'), fetchAmount($dummydata, $openQuery, 'Open'));
			
			echo json_encode($resultArray, JSON_NUMERIC_CHECK);
	}
}	
