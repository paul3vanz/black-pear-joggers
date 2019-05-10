import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'formatGender'
})
export class FormatGenderPipe implements PipeTransform {

  transform(value: string, format: string): string {
    const gender = {
      'M': 'Male',
      'W': 'Female'
    }[value] || value;

    return format === 'short' ? gender.slice(0, 1) : gender;
  }

}
