import { Component, Input, Output, EventEmitter } from '@angular/core';
import { ClubRecord } from '../../models/club-record.model';

@Component({
  selector: 'bpj-club-records-table',
  templateUrl: './club-records-table.component.html',
  styleUrls: [ './club-records-table.component.scss' ],
})
export class ClubRecordsTableComponent {
  @Input() records: ClubRecord[];
  @Input() showPace = false;
  @Input() showSubheading = true;
  @Output() query = new EventEmitter<ClubRecord>();
  @Output() toggleFormat = new EventEmitter();

  onQuery(record: ClubRecord) {
    this.query.emit(record);
  }

  onToggleFormat() {
    this.toggleFormat.emit();
  }
}
