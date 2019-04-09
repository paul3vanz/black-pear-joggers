import { Pipe, PipeTransform } from '@angular/core';
import { ClubRecord } from '../models/club-record.model';

interface FilterOptions {
  gender: string;
  category: string;
}

@Pipe({
  name: 'filterCategory',
})
export class FilterCategoryPipe implements PipeTransform {
  transform(results: ClubRecord[], filterOptions: FilterOptions): any {
    return results.filter((result) => {
      return result.gender === filterOptions.gender && result.category === filterOptions.category;
    });
  }
}
