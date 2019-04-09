import { Component, OnInit, Input } from '@angular/core';
import { ClubRecord } from 'apps/club-records/src/app/models/club-record.model';
import { Actions, ofType } from '@ngrx/effects';
import { ClubRecordsActionTypes, fromClubRecordsActions } from '../../+state/club-records.actions';
import { Store } from '@ngrx/store';

export interface QueryRecord {
  record?: ClubRecord;
  reason?: string;
}

@Component({
  selector: 'bpj-query-record-modal',
  templateUrl: './query-record-modal.component.html',
  styleUrls: [ './query-record-modal.component.scss' ],
})
export class QueryRecordModalComponent implements OnInit {
  @Input() record: ClubRecord;
  reason: string;
  isOpen = false;
  showError = false;
  showSuccess = false;
  model: QueryRecord = {};

  constructor(private $actions: Actions, private store$: Store<any>) {
    this.$actions.pipe(ofType(ClubRecordsActionTypes.Select)).subscribe((action) => {
      this.isOpen = true;
    });

    this.$actions.pipe(ofType(ClubRecordsActionTypes.SendQuerySuccess)).subscribe((action) => {
      this.showSuccess = true;
    });

    this.$actions.pipe(ofType(ClubRecordsActionTypes.SendQueryError)).subscribe((action) => {
      this.showError = true;
    });
  }

  onCloseModal() {
    this.isOpen = false;
    console.log('onCloseModal');
  }

  onSubmit() {
    this.store$.dispatch(new fromClubRecordsActions.SendQuery(this.record, this.model.reason));
  }

  ngOnInit() {}
}
