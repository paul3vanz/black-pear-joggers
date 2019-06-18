import { Component, OnInit } from '@angular/core';
import { AwardClaimService } from 'libs/club-standards-data-access/src/lib/services/award-claim.service';
import { Observable } from 'rxjs';
import { AwardClaim } from 'libs/club-standards-data-access/src/lib/models/award-claim.model';
import { take } from 'rxjs/operators';

@Component({
  selector: 'bpj-club-standards-page',
  templateUrl: './club-standards-page.component.html',
  styleUrls: [ './club-standards-page.component.scss' ],
})
export class ClubStandardsPageComponent implements OnInit {
  awardClaims$: Observable<AwardClaim[]>;
  activeModal: string;
  selectedAwardClaim: AwardClaim;

  constructor(private awardClaimService: AwardClaimService) {}

  ngOnInit() {
    this.awardClaims$ = this.awardClaimService.getAll();
  }

  onModalClose() {
    this.selectedAwardClaim = null;
    this.activeModal = null;
  }

  onViewRaces(awardClaim: AwardClaim) {
    this.selectedAwardClaim = awardClaim;
    this.activeModal = 'viewRaces';
  }

  onEdit(awardClaim: AwardClaim) {
    this.selectedAwardClaim = awardClaim;
    this.activeModal = 'edit';
  }

  onToggleVerify(awardClaim: AwardClaim) {
    this.awardClaimService.toggleVerified(awardClaim).pipe(take(1)).subscribe(() => {
      this.awardClaims$ = this.awardClaimService.getAll();
      // this.awardClaimService.getAll().pipe(take(1)).subscribe(() => {
      //   this.awardClaims$
      // });
    });
  }

  onArchive(awardClaim: AwardClaim) {
    this.awardClaimService.archive(awardClaim).pipe(take(1)).subscribe(() => {
      this.awardClaims$ = this.awardClaimService.getAll();
    });
  }

  onDelete(awardClaim: AwardClaim) {
    this.awardClaimService.delete(awardClaim).pipe(take(1)).subscribe(() => {
      this.awardClaims$ = this.awardClaimService.getAll();
    });
  }
}
