import { Component, OnInit, Input } from '@angular/core';
import { AwardClaim } from 'libs/club-standards-data-access/src/lib/models/award-claim.model';

@Component({
  selector: 'bpj-edit-award-claim-modal',
  templateUrl: './edit-award-claim-modal.component.html',
  styleUrls: [ './edit-award-claim-modal.component.scss' ],
})
export class EditAwardClaimModalComponent implements OnInit {
  @Input() awardClaim: AwardClaim;

  constructor() {}

  ngOnInit() {}
}
