<?php

$router->get('/', function () use ($router) {
    return $router->app->version();
});


$router->get('/athlete/{id}', 'AthleteController@getAthlete');
$router->get('/athlete/{id}/performances', 'PerformanceController@getPerformancesByAthlete');
$router->get('/athletes', 'AthleteController@getAthletes');
$router->get('/athletes/awards', 'AwardController@getAthleteAwards');

$router->get('/awardclaim', 'AwardClaimController@getAll');
$router->post('/awardclaim', 'AwardClaimController@submitClaim');

$router->get('/awards', 'AwardController@getAwards');

$router->get('/events', 'EventController@getEvents');

$router->get('/fetch/performances/{athleteId}', 'FetchController@fetchPerformances');
$router->get('/fetch/performances', 'FetchController@queueAllFetchPerformances');

$router->get('/registrations/queue', 'RegistrationController@queueAllRegistrations');

$router->get('/magicmile', 'MagicMileController@getAllLegacy');
$router->get('/magicmile/create', 'MagicMileController@create');
$router->post('/magicmile', 'MagicMileController@store');

$router->get('/members/totals', 'AthleteController@getMembershipTotals');

$router->get('/membership/update', 'MembershipController@updateMembershipStatus');
$router->get('/membership/{firstName}/{lastName}/{dateOfBirth}', 'MembershipController@checkNameDob');
$router->get('/membership/{urn}', 'MembershipController@responseCheckUrn');

$router->get('/parkrunalphabet', 'PerformanceController@getParkrunAlphabet');

$router->get('/parkruntourists', 'PerformanceController@getParkrunTourists');

$router->get('/performances', 'PerformanceController@getPerformanceSummaries');
$router->get('/performances/{date}/{meeting}', 'PerformanceController@getPerformancesByMeeting');

$router->get('/records', 'PerformanceController@getRecords');
$router->post('/records/query', 'PerformanceController@queryRecord');

$router->get('/standards', 'StandardController@getStandards');
$router->get('/standards/{gender}', 'StandardController@getStandardsByGender');
$router->get('/standards/{gender}/{category}', 'StandardController@getStandardsByCategory');

$router->get('/test', 'TestController@test');

$router->get('/uka', 'ScraperController@fetchMembers');