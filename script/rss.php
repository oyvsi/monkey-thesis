<?php
/*
 * Downloads an rss-feed and serve the item titles as
 * a json array
 */
require_once('config.php');
if(isset($_GET['url'])) {
	$data = array();
	$xml = simplexml_load_string(file_get_contents($_GET['url']));
	
	if(!$xml)
		die('unable to load rss feed');

	foreach($xml->channel->item as $item) {
		// Hardcoded in the rss-feed for driftsmeldinger, we don't want to include it
    	if($item->title != 'Det er for tiden ingen driftsmeldinger.') {
        array_push($data, (string) $item->title);
    	}
	}
	if($dummydata) {
		echo json_encode(array("Det er planlagt driftsarbeid på mail-servere natt til 03. mai mellom 02.00 og 02:30", "Det kan oppleves noe treghet på terminalservere. Det jobbes med å utbedre dette."));
	} else {
		echo json_encode($data);
	}
} else {
	echo "Must be called with url as get param";
}
