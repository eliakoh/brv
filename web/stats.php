<?php

if(php_sapi_name() == 'cli') {
  require(__DIR__ . '/vendor/autoload.php');
  require(__DIR__ . '/../crud/transform.php');

  $api = new RestClient([
      'base_url' => "http://localhost/crud/api.php",
      'format' => "json",
  ]);

  $api->register_decoder('json', function($data){
    return json_decode($data, TRUE);
  });

  $result = $api->get('/players?include=games,players_stats');
  if($result->info->http_code == 200) {
    $response_array = $result->decode_response();
    $response_array = php_crud_api_transform($response_array);
    $leaderboard_array = array();

    foreach($response_array['players'] as $player) {
      if($player['status'] == 0) continue;

      $totalkills = 0;

      foreach($player['players_stats'] as $stat) {
        $totalkills += $stat['kills'];
      }

      $leaderboard_array[] = array(
        'name' => $player['name'],
        'games' => count($player['players_stats']),
        'wins' => count($player['games']),
        'kills' => $totalkills
      );
    }

    uasort($leaderboard_array, 'cmp');
    $leaderboard_array = array_slice($leaderboard_array, 0, 20);

    $response_json = json_encode($leaderboard_array, JSON_UNESCAPED_UNICODE);
    file_put_contents(__DIR__ . '/stats.json', $response_json);
  }
}

function cmp($a, $b) {
  if ($a['games'] == $b['games']) {
    return 0;
  }
  return ($b['games'] < $a['games']) ? -1 : 1;
}
