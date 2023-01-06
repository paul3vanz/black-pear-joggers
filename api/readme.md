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

### Meetings

- All meetings (recent first)
  - https://bpj.org.uk/api/public/index.php/meetings
- Search event name (needs to be extended to allow multiple)
  - https://bpj.org.uk/api/public/index.php/meetings?search=evesham
- Filter on year
  - https://bpj.org.uk/api/public/index.php/meetings?year=2015
- Filter on event (needs to be extended to allow multiple)
  - https://bpj.org.uk/api/public/index.php/meetings?event=parkrun
- Filter on date (needs fixing to allow both from and to together)
  - https://bpj.org.uk/api/public/index.php/meetings?fromDate=2022-12-30
  - https://bpj.org.uk/api/public/index.php/meetings?toDate=2022-12-30

### Performances (results)

- All performances
  - https://bpj.org.uk/api/public/index.php/performances
- Filter on athlete
  - https://bpj.org.uk/api/public/index.php/performances?athleteId=450606
- Search event name
  - https://bpj.org.uk/api/public/index.php/performances?search=croome
- Filter on age category
  - https://bpj.org.uk/api/public/index.php/performances?category=V40
- Filter on gender (e.g. M or W)
  - https://bpj.org.uk/api/public/index.php/performances?category=M
- Filter on event
  - https://bpj.org.uk/api/public/index.php/performances?event=HM
- Filter on date (needs fixing to allow both from and to together)
  - https://bpj.org.uk/api/public/index.php/performances?fromDate=
  - https://bpj.org.uk/api/public/index.php/performances?toDate=
- Filter on PBs only
  - https://bpj.org.uk/api/public/index.php/performances?isPersonalBest=1
- Limit number of records for performance reasons (e.g. show latest 50)
  - https://bpj.org.uk/api/public/index.php/performances?limit=
- Results for specific meeting
  - https://bpj.org.uk/api/public/index.php/performances?meetingId=6ed1ee94-d938-4762-8bb9-b2beb4f4c185
- Filter by only awards (e.g. Bronze, Silver, etc)
  - https://bpj.org.uk/api/public/index.php/performances?onlyAwards=
- Override sort order (needs updating to allow more options, defaults to most recent date)
  - https://bpj.org.uk/api/public/index.php/performances?sort=athlete

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
