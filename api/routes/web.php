<?php

$router->get('/', function () use ($router) {
    return $router->app->version();
});

$router->get('/athletes', 'AthleteController@getAthletes');
$router->get('/athlete/{id}', 'AthleteController@getAthlete');
$router->post('/athlete', 'AthleteController@createAthlete');
$router->put('/athlete/{id}', 'AthleteController@updateAthlete');
$router->delete('/athlete/{id}', 'AthleteController@deleteAthlete');
$router->get('/athleteIdvCheck', 'AthleteController@athleteIdvCheck');

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
    $router->patch('{id}', 'AwardClaimController@update');
});

$router->group(['middleware' => 'auth', 'prefix' => 'membership'], function ($router) {
    $router->get('{firstName}/{lastName}/{dateOfBirth}', 'MembershipController@checkNameDob');
    $router->get('{urn}', 'MembershipController@responseCheckUrn');
});

$router->group(['middleware' => 'auth', 'prefix' => 'clubs'], function ($router) {
    $router->get('', 'MembershipController@getClubs');
    $router->get('{clubId}/members', 'MembershipController@getClubMembers');
});

$router->get('storeClubMembers', 'MembershipController@storeClubMembers');

$router->get('/awards', 'AwardController@getAwards');

$router->post('/checkout', 'CheckoutController@createSession');

$router->get('/events', 'EventController@getEvents');

$router->group(['prefix' => 'fetch'], function ($router) {
    $router->get('performances/{athleteId}', 'FetchPerformancesController@fetchPerformances');
    $router->get('performances', 'FetchPerformancesController@queueAllFetchPerformances');
    $router->get('rankings/{athleteId}', 'FetchRankingsController@fetchRankings');
    $router->get('rankings', 'FetchRankingsController@queueAllFetchRankings');
    $router->get('updatepersonalbests', 'FetchPerformancesController@updatePersonalBests');
});

$router->get('/registrations/queue', 'RegistrationController@queueAllRegistrations');
$router->get('/registrations/createregistrationsfrommemberships', 'RegistrationController@createRegistrationsFromMemberships');

$router->get('/magicmile', 'MagicMileController@getAllLegacy');
$router->get('/magicmile/syncmagicmile', 'MagicMileController@syncMagicMileResults');

$router->group([
    'middleware' => 'auth',
    'prefix' => 'magicmile',
],  function ($router) {
    $router->post('', 'MagicMileController@store');
    $router->delete('{id}', 'MagicMileController@delete');
});

$router->get('/members/totals', 'AthleteController@getMembershipTotals');
$router->get('/members/leaguemembers', 'MembershipController@getRegisteredMembers');

$router->get('/parkrunalphabet', 'ParkrunController@getParkrunAlphabet'); // Deprecated
$router->get('/parkruntourists', 'ParkrunController@getParkrunTourists'); // Deprecated

$router->group(['prefix' => 'parkrun'], function ($router) {
    $router->get('alphabet', 'ParkrunController@getParkrunAlphabet');
    $router->get('tourists', 'ParkrunController@getParkrunTourists');
});

$router->get('/performances', 'PerformanceController@getPerformanceSummaries');
$router->get('/performances/{date}/{meeting}', 'PerformanceController@getPerformancesByMeeting');
$router->get('/performances/{id}', 'PerformanceController@getPerformance');

$router->get('/performancesindividual', 'PerformanceController@getPerformancesIndividual');

$router->get('/rankings/{athleteId}', 'RankingController@getRankingsByAthlete');
$router->get('/rankings/{athleteId}/{year}', 'RankingController@getRankingsByAthlete');

$router->group(['prefix' => 'records'], function ($router) {
    $router->get('', 'RecordsController@getRecords');
    $router->post('query', 'RecordsController@queryRecord');
});

$router->get('/standards', 'StandardController@getStandards');
$router->get('/standards/{gender}', 'StandardController@getStandardsByGender');
$router->get('/standards/{gender}/{category}', 'StandardController@getStandardsByCategory');

$router->get('/test', 'TestController@test');

$router->get('/uka', 'ScraperController@fetchMembers');

$router->group(['middleware' => 'auth', 'prefix' => 'user'], function ($router) {
    $router->get('', 'UserController@getUser');
    $router->put('', 'UserController@setUser');
    $router->get('/token', 'UserController@getToken');
});
