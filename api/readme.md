Launch API server locally:
php -S localhost:8000 -t public

Run migrations for new stuff only:
php artisan migrate --path=/database/migrations/test/

Logs in storage\logs\lumen.log

Tasks:

- Fetch and parse power of 10 data for athlete
- Fetch and parse run britain rankings for athlete
-

Local installation instructions
Install XAMPP and point vhost to working directory
Install Composer
Run 'composer install' from api folder

{
standard(category: V35, gender: M) {
gender
category
time
timeParsed
award {
name
}
event {
event
distance
}
}
}

query FetchMagicMile($category: Category) {
  magicMile(category: $category) {
id
athleteId
firstName
lastName
gender
category
date
location
predictedTime
predictedTimeParsed
actualTime
actualTimeParsed
}
}

{
performance(id:2) {
id
athlete {
id
firstName
lastName
}
category
date
event
time
timeParsed
}
}
