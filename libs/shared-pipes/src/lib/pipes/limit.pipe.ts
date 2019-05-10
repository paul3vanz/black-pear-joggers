import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'limit',
})
export class LimitPipe implements PipeTransform {
  transform(array: any[], start: number, end: number): any[] {
    return array.slice(start - 1, end);
  }
}
