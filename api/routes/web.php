<?php

$router->get('/', function () use ($router) {
    return $router->app->version();
});

$router->get('/athletes', 'AthleteController@getAthletes');
$router->get('/athlete/{id}', 'AthleteController@getAthlete');
$router->post('/athlete', 'AthleteController@createAthlete');
$router->put('/athlete/{id}', 'AthleteController@updateAthlete');
$router->delete('/athlete/{id}', 'AthleteController@deleteAthlete');

$router->get('/athlete/{id}/performances', 'PerformanceController@getPerformancesByAthlete');
$router->get('/athletes/awards', 'AwardController@getAthleteAwards');

$router->get('/awardclaim/{id}/{uniqueToken}', 'AwardClaimController@getClaim');
$router->post('/awardclaim', 'AwardClaimController@submitClaim');
$router->post('/awardclaim/{id}/race', 'AwardClaimController@submitClaimRace');

$router->group([
    'middleware' => 'auth',
    'prefix' => 'awardclaim',
],  function ($router) {
    $router->post('toggleverified/{id}', 'AwardClaimController@toggleVerified');
    $router->post('archive/{id}', 'AwardClaimController@archive');
    $router->post('delete/{id}', 'AwardClaimController@delete');
    $router->get('', 'AwardClaimController@getAll');
});

$router->group(['middleware' => 'auth', 'prefix' => 'membership'], function ($router) {
    $router->get('{firstName}/{lastName}/{dateOfBirth}', 'MembershipController@checkNameDob');
    $router->get('{urn}', 'MembershipController@responseCheckUrn');
});

$router->group(['middleware' => 'auth', 'prefix' => 'clubs'], function ($router) {
    $router->get('', 'MembershipController@getClubs');
    $router->get('{clubId}/members', 'MembershipController@getClubMembers');
    $router->get('store', 'MembershipController@storeClubMembers');
});

$router->get('/awards', 'AwardController@getAwards');

$router->get('/events', 'EventController@getEvents');

$router->group(['middleware' => 'auth', 'prefix' => 'fetch'], function ($router) {
    $router->get('performances/{athleteId}', 'FetchPerformancesController@fetchPerformances');
    $router->get('performances', 'FetchPerformancesController@queueAllFetchPerformances');
    $router->get('rankings/{athleteId}', 'FetchRankingsController@fetchRankings');
    $router->get('rankings', 'FetchRankingsController@queueAllFetchRankings');
    $router->get('updatepersonalbests', 'FetchPerformancesController@updatePersonalBests');
});

$router->get('/registrations/queue', 'RegistrationController@queueAllRegistrations');
$router->get('/registrations/createregistrationsfrommemberships', 'RegistrationController@createRegistrationsFromMemberships');

$router->get('/magicmile', 'MagicMileController@getAllLegacy');
$router->post('/magicmile', 'MagicMileController@store');
$router->delete('/magicmile/{id}', 'MagicMileController@delete');

$router->get('/members/totals', 'AthleteController@getMembershipTotals');

$router->get('/parkrunalphabet', 'PerformanceController@getParkrunAlphabet');

$router->get('/parkruntourists', 'PerformanceController@getParkrunTourists');

$router->get('/performances', 'PerformanceController@getPerformanceSummaries');
$router->get('/performances/{date}/{meeting}', 'PerformanceController@getPerformancesByMeeting');
$router->get('/performances/syncmagicmile', 'PerformanceController@syncMagicMileResults');

$router->get('/rankings/{athleteId}', 'RankingController@getRankingsByAthlete');
$router->get('/rankings/{athleteId}/{year}', 'RankingController@getRankingsByAthlete');

$router->get('/records', 'PerformanceController@getRecords');
$router->post('/records/query', 'PerformanceController@queryRecord');

$router->get('/standards', 'StandardController@getStandards');
$router->get('/standards/{gender}', 'StandardController@getStandardsByGender');
$router->get('/standards/{gender}/{category}', 'StandardController@getStandardsByCategory');

$router->get('/test', 'TestController@test');

$router->get('/uka', 'ScraperController@fetchMembers');
