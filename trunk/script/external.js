// Generic ajax function
function ajax(arg, func, url) {
	var errorID = 'error_' + func.name;
	$.ajax({
		type: 'GET',
		url: url,
		data: arg
	}).done(function(data, text, jqXHR) {
		if($('#' + errorID).length > 0)
			$('#' + errorID).remove(); 
		func(data);
	}).fail(function(jqXHR, textStatus, errorThrown) {
		var error = '<div id="' + errorID + '" class="status_red">Error contacting: ' + url + ' for function: ' + func.name + '</div>';
		if($('#' + errorID).length == 0)
			$("#top").append(error);		
	});
}

// Callback function for temperature
// Sets all temperature sensor values
function temp(sensor_data) {
	var front_layout = [2, 1];	// The netbotz sensor IDs for the front row
	var back_layout = [5, 4];	// and the back
	var columns = Math.max(front_layout.length, back_layout.length); // Largest row is used for drawing columns

	var front_data = new Array();
	var back_data = new Array();

	// Loop all sensors and add the value to the array where it belongs (taken from the layouts)
	$.each($.parseJSON(sensor_data), function(index, sensor) {
		if(front_layout.indexOf(sensor.name) > -1) {
			front_data[front_layout.indexOf(sensor.name)] = sensor.data;
	  	}
	  	else if(back_layout.indexOf(sensor.name) > -1) {
			back_data[back_layout.indexOf(sensor.name)] = sensor.data;
	  	}
	});

	// Generate HTML
	var html = "<div id=\"back\">";
	for(var i in back_data) {
		html += "<span id=\"temp_sensor_back_" + i + "\" class=\"temp_sensor_back\">" + back_data[i] + "&degC</span>";
	}
	
	html += "</div><div id=\"front\">";
  
	for(var i in front_data) {
		html += "<span id=\"temp_sensor_front_" + i + "\" class=\"temp_sensor_front\">" + front_data[i] + "&degC</span>";
	}
	
	html += "</div>";

	var room = new Image(); // Set up background image for the div
	room.onload = function() {
		$('#serverroom_climate').css('width', this.width);
		$('#serverroom_climate').css('height', this.height);
		$('#serverroom_climate').css('background-image', 'url(' + this.src + ')');
	};
	
	// Set the background image to be one with the right number of columns
	room.src = "image.php?sensor_cols=" + columns;  
	// Set the sensor values in the data div
	$('#serverroom_climate #temperature #data').html(html);
}

// Callback function for humidity
// Sets the mean humidity value
function humid(sensor_data) {
	var total = 0;
	var sensors = $.parseJSON(sensor_data);
	
	// Generate the total by looping all sensors
	$.each(sensors, function(index, sensor) {
		total += sensor.data;
  	});
	var mean = Math.round(total/sensors.length);

  $('#serverroom_climate #humidity #data').html(mean + '%');
}

function getGraphStats(graphStats) {
//	var barArray = new Array();
	var stats = $.parseJSON(graphStats);
	
	$('#graph').highcharts({
		chart: {
			renderTo: 'graph',
			width: 400,
			height: 175,
			animation: false,
			defaultSeriesType: 'column',
			marginTop: 26
		},
		title: {
			text: null
		},
		xAxis: {
			categories: ['Closed(today)', 'Received(today)', 'Closed(overall)', 'Active(overall)']
		},
		yAxis: {
			title: {
				text: null 
			},
			endOnTick: false,
			max: Math.max(stats.Open, stats.Closed, stats.ClosedAll, stats.Received)
		},
		legend: {
			enabled: false
		},
		labels: {
			rotation: -45,						 
			align: 'right'	
		},
		series: [{
			name: 'Amount',
			data: [{ y: stats.Closed,
						color: '#32CD32'},
					 { y: stats.Received,
				 color: '#FF0000'},
					 { y: stats.ClosedAll,
				 color: '#32CD32'},
					 { y: stats.Open,
				 color: '#FF8F00'}
					]
			}],
		plotOptions: {
			column: {
				dataLabels: {
					enabled: true,
					style: {
						fontSize: "16px",
						lineHeight: "auto"
					}
				},
				animation: false, 
				pointWidth: 30,        
		  		borderWidth: 1
			}
		},

		tooltip: {
			enabled: false
		},
		credits: {
			enabled: false
		}
	});
}

// Callback function for rss feed
// Sets the #feed #data div. 
// If all feed items are longer than the div we make the text scroll
function feed(data) {
	var html = '';

	$.each($.parseJSON(data), function(key, val) {
		html += '&#x25cf; ' + val + '&nbsp;&nbsp;&nbsp;&nbsp';
	});
	
	$("#feed #data").html(html);
	var feedWidth = $("#feed #data")[0].scrollWidth;
	var areaWidth = $("#feed #data").width();

	if(feedWidth > areaWidth) {
		$("#feed #data").css("overflow", "hidden");
		$("#feed #data").marquee({
			speed: 30000
		});
	}
}

function nagdash(data) {
	$('#nagioscontainer').html(data);
}

// Set up all our functions to run and rerun
function load() {
	(function contDelay() {
		ajax(null, nagdash, 'nagdash.php');
		ajax({type: "Temperature"}, temp, 'netbotz.php');
		ajax({type: "Humidity"}, humid, 'netbotz.php');
		ajax({type: "Graph"}, getGraphStats, 'footprints.php');
		setTimeout(contDelay, 200000);
	})();

	(function feedDelay(){
		ajax({url: 'https://portal.hedmark.org/driftsfeed.php'}, feed, 'rss.php'); 
		setTimeout(feedDelay, 100000);
	})();
}

$(document).ready(function() {
	$.ajaxSetup({ cache: false });
	load();
});
