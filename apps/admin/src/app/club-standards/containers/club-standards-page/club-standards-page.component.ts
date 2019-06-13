import { Component, OnInit } from '@angular/core';
import { AwardClaimService } from 'libs/club-standards-data-access/src/lib/services/award-claim.service';
import { Observable } from 'rxjs';
import { AwardClaim } from 'libs/club-standards-data-access/src/lib/models/award-claim.model';

@Component({
  selector: 'bpj-club-standards-page',
  templateUrl: './club-standards-page.component.html',
  styleUrls: [ './club-standards-page.component.scss' ],
})
export class ClubStandardsPageComponent implements OnInit {
  awardClaims$: Observable<AwardClaim[]>;
  selectedAwardClaim: AwardClaim;

  constructor(private awardClaimService: AwardClaimService) {}

  ngOnInit() {
    this.awardClaims$ = this.awardClaimService.getAll();
  }

  onModalClose() {
    this.selectedAwardClaim = null;
  }

  onEdit(awardClaim: AwardClaim) {
    this.selectedAwardClaim = awardClaim;
  }
}
