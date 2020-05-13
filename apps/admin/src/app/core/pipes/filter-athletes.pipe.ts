import { Pipe, PipeTransform } from '@angular/core';

import { Athlete } from '@black-pear-joggers/race-results-data-access';

@Pipe({
  name: 'filterAthletes'
})
export class FilterAthletesPipe implements PipeTransform {
  transform(athletes: Athlete[], search: string): Athlete[] {
    if (!search) {
      return athletes;
    }

    return athletes.filter(athlete => {
      const regex = new RegExp(search, 'i');

      return (
        athlete.first_name.match(regex) ||
        athlete.last_name.match(regex) ||
        [athlete.first_name, athlete.last_name].join(' ').match(regex)
      );
    });
  }
}
