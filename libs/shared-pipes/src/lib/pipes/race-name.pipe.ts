import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'raceName',
})
export class RaceNamePipe implements PipeTransform {
  transform(race: string): string {
    return race.length > 50 ? race.replace(/ inc\..*/, '') : race;
  }
}
