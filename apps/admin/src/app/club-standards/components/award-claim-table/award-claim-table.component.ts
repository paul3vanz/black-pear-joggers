import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import { AwardClaim } from 'libs/club-standards-data-access/src/lib/models/award-claim.model';

@Component({
  selector: 'bpj-award-claim-table',
  templateUrl: './award-claim-table.component.html',
  styleUrls: [ './award-claim-table.component.scss' ],
})
export class AwardClaimTableComponent implements OnInit {
  @Input() awards: AwardClaim[];
  @Output() edit = new EventEmitter<AwardClaim>();

  constructor() {}

  ngOnInit() {}

  onEditClick(awardClaim: AwardClaim) {
    this.edit.emit(awardClaim);
  }
}
