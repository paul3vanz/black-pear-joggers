import { Component, OnInit, Input } from '@angular/core';
import { AwardClaim } from 'libs/club-standards-data-access/src/lib/models/award-claim.model';

@Component({
  selector: 'bpj-validation-check-modal',
  templateUrl: './validation-check-modal.component.html',
  styleUrls: ['./validation-check-modal.component.scss']
})
export class ValidationCheckModalComponent implements OnInit {
  @Input() awardClaim: AwardClaim;

  constructor() { }

  ngOnInit() {
  }

}
