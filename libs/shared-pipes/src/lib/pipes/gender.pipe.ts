import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'gender',
})
export class GenderPipe implements PipeTransform {
  transform(value: string, format: string): string {
    const gender = value === 'M' ? 'Male' : 'Female';

    return format === 'short' ? gender.substring(0, 1) : gender;
  }
}
