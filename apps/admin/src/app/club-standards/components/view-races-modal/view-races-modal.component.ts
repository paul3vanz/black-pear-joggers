import { Component, OnInit, Input } from '@angular/core';
import { AwardClaim } from 'libs/club-standards-data-access/src/lib/models/award-claim.model';

@Component({
  selector: 'bpj-view-races-modal',
  templateUrl: './view-races-modal.component.html',
  styleUrls: ['./view-races-modal.component.scss']
})
export class ViewRacesModalComponent implements OnInit {
  @Input() awardClaim: AwardClaim;

  constructor() { }

  ngOnInit() {
  }

}
