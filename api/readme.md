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

  - Fetches all members direct from UKA API
  - Filters to keep just Registered members
  - Filters to remove members already in athletes table (matching against URN)
  - Adds the remaining 'new' members to the registration table
  - These will be picked up

- 00:05: queue:fetch:memberships
- 01:00: queue:fetch:performances
- 04:00: queue:fetch:rankings
- 05:00: queue:work --stop-when-empty
- 07:00: queue:fetch:updatepersonalbests

## Available endpoints

Here is an overview of common endpoints for retrieving data. There's additional ones for updating, fetching and some need auth tokens to access.

### Athletes

- All athletes
  - https://bpj.org.uk/api/public/index.php/athletes
- Specific athlete
  - https://bpj.org.uk/api/public/index.php/athlete/450606
- Identity check
  - https://bpj.org.uk/api/public/index.php/athleteIdvCheck?urn=1234567&dob=1983-01-01

### Performances (results)

- By athlete
  - https://bpj.org.uk/api/public/index.php/athlete/450606/performances
- All performances
  - https://bpj.org.uk/api/public/index.php/performances
- Search event name
  - https://bpj.org.uk/api/public/index.php/performances?search=croome
- PBs
  - https://bpj.org.uk/api/public/index.php/performancesindividual?isPersonalBest=1

### Club standards award standards

- All
  - https://bpj.org.uk/api/public/index.php/standards
- By gender
  - https://bpj.org.uk/api/public/index.php/standards/M
- By gender and category
  - https://bpj.org.uk/api/public/index.php/standards/W/V60

### Club records

- All records
  - https://bpj.org.uk/api/public/index.php/records

### Rankings

- By athlete
  - https://bpj.org.uk/api/public/index.php/rankings/450606
- By athlete and year
  - https://bpj.org.uk/api/public/index.php/rankings/450606/2013

### Events

- All events
  - https://bpj.org.uk/api/public/index.php/events

### Awards

- All awards
  - https://bpj.org.uk/api/public/index.php/awards

### Magic mile

- All magic mile results
  - https://bpj.org.uk/api/public/index.php/magicmile

### Fetching data

https://bpj.org.uk/api/public/index.php/fetch/performances/450606

## Other commands locally

### Migrations

php artisan migrate
php artisan migrate:status
php artisan migrate --pretend
php artisan migrate --force
php artisan migrate:rollback
php artisan schema:dump
php artisan schema:dump --prune
