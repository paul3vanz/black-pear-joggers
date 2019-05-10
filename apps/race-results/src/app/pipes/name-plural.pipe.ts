import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'namePlural'
})
export class NamePluralPipe implements PipeTransform {

  transform(value: string): string {
    return (value.slice(-1) === 's') ? `${value}'` : `${value}'s`;
  }

}
