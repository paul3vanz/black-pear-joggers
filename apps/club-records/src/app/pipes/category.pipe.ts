import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'category',
})
export class CategoryPipe implements PipeTransform {
  transform(value: string): string {
    switch (value.substring(0, 1)) {
      case 'U':
        return `${value} (Under ${value.slice(1)})`;
      case 'S':
        return 'Senior (23-34)';
      case 'V':
        return `${value} (Veteran ${value.slice(1)}-${parseInt(value.slice(1)) + 4})`;
      default:
        return value;
    }
  }
}
