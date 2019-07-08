import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import { AwardClaim } from 'libs/club-standards-data-access/src/lib/models/award-claim.model';

@Component({
  selector: 'bpj-award-claim-table',
  templateUrl: './award-claim-table.component.html',
  styleUrls: [ './award-claim-table.component.scss' ],
})
export class AwardClaimTableComponent implements OnInit {
  @Input() set awards(awards: AwardClaim[]) {
    this._awards = awards.filter(award => !award.archived);
  };

  @Output() viewRaces = new EventEmitter<AwardClaim>();
  @Output() edit = new EventEmitter<AwardClaim>();
  @Output() archive = new EventEmitter<AwardClaim>();
  @Output() delete = new EventEmitter<AwardClaim>();
  @Output() toggleVerify = new EventEmitter<AwardClaim>();

  _awards: AwardClaim[];

  constructor() {}

  ngOnInit() {}

  onViewRacesClick(awardClaim: AwardClaim) {
    this.viewRaces.emit(awardClaim);
  }

  onEditClick(awardClaim: AwardClaim) {
    this.edit.emit(awardClaim);
  }

  onArchiveClick(awardClaim: AwardClaim) {
    this.archive.emit(awardClaim);
  }

  onDeleteClick(awardClaim: AwardClaim) {
    this.delete.emit(awardClaim);
  }

  onToggleVerifyClick(awardClaim: AwardClaim) {
    this.toggleVerify.emit(awardClaim);
  }
}
