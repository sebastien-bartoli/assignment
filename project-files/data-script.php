<?php 

$restaurants = [];
$acceptedOptions = ['AMEX', 'Visa', 'Discover', 'MasterCard'];

$json = json_decode(file_get_contents("resources/dataset/restaurants_list.json"));
$csv = explode(PHP_EOL, file_get_contents("resources/dataset/restaurants_info.csv"));

foreach ($csv as $i => $r) {
	$restaurant = explode(";", $r);
	if(!is_numeric($restaurant[0])){
		continue;
	}

	$result = array_filter($json, function($e) use ($restaurant){
		return $e->objectID == $restaurant[0];
	});
	$jsonRestaurant = reset($result);
	$jsonRestaurant->food_type = $restaurant[1];
	$jsonRestaurant->stars_count = (float)$restaurant[2];
	$jsonRestaurant->reviews_count = $restaurant[3];
	$jsonRestaurant->neighborhood = $restaurant[4];
	$jsonRestaurant->phone = $restaurant[5];
	$jsonRestaurant->price_range = $restaurant[6];
	$jsonRestaurant->dining_style = $restaurant[7];

	$changed = false;
	foreach ($jsonRestaurant->payment_options as $i => $option) {
		if(!in_array($option, $acceptedOptions)){
			$changed = true ;
			if($option == "Diners Club" || $option == "Carte Blanche"){
				if(in_array("Discover", $jsonRestaurant->payment_options)){
					unset($jsonRestaurant->payment_options[$i]);
				} else {
					$jsonRestaurant->payment_options[$i] = "Discover";
				}
 			} else {
 				unset($jsonRestaurant->payment_options[$i]);
 			}
		}
	}
	if($changed){
		$jsonRestaurant->payment_options = array_values($jsonRestaurant->payment_options);
	}
	array_push($restaurants, $jsonRestaurant);
}

$file = file_put_contents("resources/dataset/final-dataset.json", json_encode($restaurants));
echo $file;
?>