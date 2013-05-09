<?php
/**
 * Servers an illustration of the server room based on the number of sensors in a column.
 * Author: MonKey, 2013
 * Last edited: 24.04.2013
 */

// Exit if we have no get param
if(!(isset($_GET['sensor_cols']) && is_numeric($_GET['sensor_cols'])))
	die('Needs to be called with a numeric get param of sensor_cols');

$base 	= 'img/room.png';	// The start image
$add 		= 'img/room_n.png'; // For each column over 1, we paste in one of this
$no_add 	= $_GET['sensor_cols'] - 1; // number of columns to add

// Create images
$base_image = imagecreatefrompng($base);
$add_image 	= imagecreatefrompng($add);

// Get original dimensions
list($base_width, $base_height) = getimagesize($base);
list($add_width, $add_height) = getimagesize($add);

// Create output image
$new = imagecreatetruecolor(($base_width+($add_width*$no_add)), $base_height);
// Set output image transparent
imagealphablending($new, false );
imagesavealpha($new, true);

// Copy our base to the output
imagecopy($new, $base_image, 0, 0, 0, 0, $base_width, $base_height);

// Add columns by copying add_image to output
for($i = 0; $i < $no_add; $i++) 
	imagecopy($new, $add_image, $base_width + ($i*$add_width), 0, 0, 0, $add_width, $add_height);

// Serve up the image
header('Content-Type: image/png');
imagepng($new);
