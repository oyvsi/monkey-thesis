<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<title>Icinga Status</title>

	<link href="style.css" rel="stylesheet">
	<link href="//netdna.bootstrapcdn.com/twitter-bootstrap/2.2.1/css/bootstrap-combined.min.css" rel="stylesheet">

	<script src="//ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script> <!-- TODO: Download to local -->
	<script src="//netdna.bootstrapcdn.com/twitter-bootstrap/2.2.1/js/bootstrap.min.js"></script>
	<script src="js/external.js"></script>
   <script src="Highcharts/js/highcharts.js"></script>
	<script src="js/clock.js"></script>
	<script src="js/jquery.marquee.js"></script>

</head>

<body>
	<div id="contents">
		<div id="top">	
			<div id="serverroom_climate">
				<div id="temperature">
					<div id="data"></div>
				</div>
					
				<div id="humidity">
					<div id="data"></div>
				</div>
			</div> <!-- end serverroom_climate -->

			<div id="clock">
					<div id="Date"></div>
				<ul>
					<li id="hours"></li>
					<li id="point">:</li>
					<li id="min"></li>
					<li id="point">:</li>
					<li id="sec"></li>
				</ul>
			</div>

			<div id="footprints">
				<div id="graph"></div>
			</div>
			<div id="feed"><div class="marquee" id="data" scrollamount="0"></marquee></div></div> 
		</div> <!-- end top -->

		<div id="nagioscontainer"></div>
	</div> <!-- end contents -->
</body>
