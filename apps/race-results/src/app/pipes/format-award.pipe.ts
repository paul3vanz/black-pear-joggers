import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'formatAward',
})
export class FormatAwardPipe implements PipeTransform {
  transform(value: string): string {
    return [ '', 'Bronze', 'Silver', 'Gold', 'Platinum' ][value] || '';
  }
}
