<?php

$router->get('/', function () use ($router) {
    return $router->app->version();
});

$router->get('/athletes', 'AthleteController@getAthletes');
$router->get('/athlete/{id}', 'AthleteController@getAthlete');
$router->post('/athlete', 'AthleteController@createAthlete');
$router->patch('/athlete/{id}', 'AthleteController@updateAthlete');
$router->patch('/athletes/{id}', 'AthleteController@updateAthlete'); // TEMP FIX AS FE POINTING TO WRONG ONE
$router->delete('/athlete/{id}', 'AthleteController@deleteAthlete');
$router->get('/athleteIdvCheck', 'AthleteController@athleteIdvCheck');

$router->get('/athletes/awards', 'AwardController@getAthleteAwards');

$router->get('/awardclaim/{id}/{uniqueToken}', 'AwardClaimController@getClaim');
$router->post('/awardclaim', 'AwardClaimController@submitClaim');
$router->post('/awardclaim/{id}/race', 'AwardClaimController@submitClaimRace');

$router->group([
    'middleware' => 'auth',
    'prefix' => 'awardclaim',
], function ($router) {
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

$router->get('/logs', 'LogsController@getLogs');

$router->get('/payments', 'PaymentsController@getPayments');
$router->get('/payments/fetch', 'FetchPaymentsController@fetchPayments');

$router->group(['prefix' => 'fetch'], function ($router) {
    $router->get('performances/{athleteId}', 'FetchPerformancesController@fetchPerformances');
    $router->get('performances', 'FetchPerformancesController@queueAllFetchPerformances');
    $router->get('rankings/{athleteId}', 'FetchRankingsController@fetchRankings');
    $router->get('rankings', 'FetchRankingsController@queueAllFetchRankings');
    $router->get('updatepersonalbests', 'FetchPerformancesController@updatePersonalBests');
});

$router->group(['middleware' => 'auth', 'prefix' => 'registrations'], function ($router) {
    $router->get('', 'RegistrationController@getAll');
    $router->delete('', 'RegistrationController@delete');
    $router->get('queue', 'RegistrationController@queueAllRegistrations');
    $router->get('createregistrationsfrommemberships', 'RegistrationController@createRegistrationsFromMemberships');
});

$router->get('/magicmile', 'MagicMileController@getAll');
$router->get('/magicmile/syncmagicmile', 'MagicMileController@syncMagicMileResults');

$router->group([
    'middleware' => 'auth',
    'prefix' => 'magicmile',
], function ($router) {
    $router->post('', 'MagicMileController@store');
    $router->delete('{id}', 'MagicMileController@delete');
});

$router->group(['prefix' => 'meetings'], function ($router) {
    $router->get('', 'MeetingController@getMeetings');
    $router->get('{id}', 'MeetingController@getMeetingById');
});

$router->get('/members/totals', 'AthleteController@getMembershipTotals');
$router->get('/members/leaguemembers', 'MembershipController@getRegisteredMembers');

$router->group(['prefix' => 'parkrun'], function ($router) {
    $router->get('alphabet', 'ParkrunController@getParkrunAlphabet');
    $router->get('tourists', 'ParkrunController@getParkrunTourists');
});

$router->group(['prefix' => 'performances'], function ($router) {
    $router->get('', 'PerformanceController@getPerformances');
    $router->get('{id}', 'PerformanceController@getPerformance');
});

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
