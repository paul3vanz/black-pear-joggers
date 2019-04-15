import { Component, OnInit, Input } from '@angular/core';
import { Actions, ofType } from '@ngrx/effects';
import { ClubStandardsActionTypes } from '../../+state/club-standards.actions';

@Component({
  selector: 'bpj-claim-award-modal',
  templateUrl: './claim-award-modal.component.html',
  styleUrls: [ './claim-award-modal.component.scss' ],
})
export class ClaimAwardModalComponent implements OnInit {
  @Input() isOpen = true;

  constructor(private actions$: Actions) {
    this.actions$.pipe(ofType(ClubStandardsActionTypes.ClubStandardsClaimStart)).subscribe(() => {
      this.isOpen = true;
    });
  }

  ngOnInit() {}

  onCloseModal() {
    this.isOpen = false;
  }
}
