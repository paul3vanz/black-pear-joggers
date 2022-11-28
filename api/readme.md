Run migrations for new stuff only:
php artisan migrate --path=/database/migrations/test/

Logs in storage\logs\lumen.log

Tasks:

- Fetch and parse power of 10 data for athlete
- Fetch and parse run britain rankings for athlete
-

## Running locally

Install PHP - a simple way is installing [XAMPP](https://www.apachefriends.org/download.html).

Install [Composer](https://getcomposer.org/download/)
and run `composer install` from api folder.

Launch API server locally:

    php -S localhost:8000 -t public

## Scheduled tasks

The following tasks run on a schedule to keep things automated:

- 00:00: queue:registrations
- 00:05: queue:fetch:memberships
- 01:00: queue:fetch:performances
- 04:00: queue:fetch:rankings
- 05:00: queue:work --stop-when-empty
- 07:00: queue:fetch:updatepersonalbests

## Available endpoints

Here is an overview of common endpoints for retrieving data. There's additional ones for updating, fetching and some need auth tokens to access.

### Athletes

- All athletes
  - http://localhost:8000/athletes
- Specific athlete
  - http://localhost:8000/athlete/450606
- Identity check
  - http://localhost:8000/athleteIdvCheck?urn=1234567&dob=1983-01-01

### Performances (results)

- By athlete
  - http://localhost:8000/athlete/450606/performances
- All performances
  - http://localhost:8000/performances
- Search event name
  - http://localhost:8000/performances?search=croome

### Club standards award standards

- All
  - http://localhost:8000/standards
- By gender
  - http://localhost:8000/standards/M
- By gender and category
  - http://localhost:8000/standards/W/V60

### Club records

- All records
  - http://localhost:8000/records

### Rankings

- By athlete
  - http://localhost:8000/rankings/450606
- By athlete and year
  - http://localhost:8000/rankings/450606/2013

### Events

- All events
  - http://localhost:8000/events

### Awards

- All awards
  - http://localhost:8000/awards

### Magic mile

- All magic mile results
  - http://localhost:8000/magicmile
