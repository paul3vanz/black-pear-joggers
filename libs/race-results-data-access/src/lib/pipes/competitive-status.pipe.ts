import { Pipe, PipeTransform } from '@angular/core';
import { CompetitiveStatus } from '../models/competitive-status.model';

@Pipe({
  name: 'competitiveStatus'
})
export class CompetitiveStatusPipe implements PipeTransform {
  transform(value: CompetitiveStatus): string {
    switch (value) {
      case CompetitiveStatus.MEMBERSHIP_WITH_CLUB_LAPSED:
        return 'Lapsed';
      case CompetitiveStatus.REGISTERED:
        return 'Registered';
      case CompetitiveStatus.REGISTRATION_BEING_PROCESSED:
        return 'Processing';
      case CompetitiveStatus.RESIGNED_FROM_CLUB:
        return 'Resigned';
    }
  }
}
