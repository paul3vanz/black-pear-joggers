import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'gender',
})
export class GenderPipe implements PipeTransform {
  transform(value: any): any {
    return value === 'M' ? 'Male' : 'Female';
  }
}
