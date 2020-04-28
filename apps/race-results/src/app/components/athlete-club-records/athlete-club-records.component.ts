import { Component, Input, ChangeDetectionStrategy } from '@angular/core';
import { ClubRecord } from '@black-pear-joggers/club-records-data-access';

@Component({
  selector: 'bpj-athlete-club-records',
  templateUrl: './athlete-club-records.component.html',
  styleUrls: ['./athlete-club-records.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class AthleteClubRecordsComponent {
  @Input() clubRecords: ClubRecord[];

  get firstName() {
    return this.clubRecords[0].first_name;
  }
}
