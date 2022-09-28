import { Athlete } from '@black-pear-joggers/core-services';

const ATHLETE_STORAGE_KEY = 'bpj.athlete';

export function storeAthlete(athlete: Athlete) {
  localStorage.setItem(
    ATHLETE_STORAGE_KEY,
    JSON.stringify({
      id: athlete.id,
      firstName: athlete.first_name,
      lastName: athlete.last_name,
      gender: athlete.gender,
      category: athlete.category,
    })
  );
}

export function getAthlete(): Athlete {
  const athlete = localStorage.getItem(ATHLETE_STORAGE_KEY);
  return athlete ? JSON.parse(athlete) : null;
}
