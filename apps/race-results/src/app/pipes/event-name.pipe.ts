import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'eventName'
})
export class EventNamePipe implements PipeTransform {

  eventAliases = {
    '1M': 'Mile',
    'Mile': 'Mile',
    '5K': '5K',
    'parkrun': '5K',
    '10K': '10K',
    '10KMT': '10K',
    'HM': 'Half Marathon',
    'HMMT': 'Half Marathon',
    'Mar': 'Marathon',
    'MarMT': 'Marathon',
};

  transform(value: string): string {
    return this.eventAliases[value];
  }

}
