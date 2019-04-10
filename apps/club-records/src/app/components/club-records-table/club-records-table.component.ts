import { Component, Input, Output, EventEmitter } from '@angular/core';
import { ClubRecord } from '../../models/club-record.model';

@Component({
  selector: 'bpj-club-records-table',
  templateUrl: './club-records-table.component.html',
  styleUrls: [ './club-records-table.component.scss' ],
})
export class ClubRecordsTableComponent {
  @Input() records: ClubRecord[];
  @Input() hideHeading: boolean;
  @Output() query = new EventEmitter<ClubRecord>();

  onQuery(record: ClubRecord) {
    this.query.emit(record);
  }
}
