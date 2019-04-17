import { Component, OnInit, Input } from '@angular/core';
import { Actions, ofType } from '@ngrx/effects';
import { ClubStandardsActionTypes } from '../../+state/club-standards.actions';
import { FormBuilder, Validators } from '@angular/forms';

@Component({
  selector: 'bpj-claim-award-modal',
  templateUrl: './claim-award-modal.component.html',
  styleUrls: [ './claim-award-modal.component.scss' ],
})
export class ClaimAwardModalComponent implements OnInit {
  @Input() isOpen = true;

  currentPage = 4;
  showValidation = false;

  claimForm = [
    this.formBuilder.group(
      {
        firstName: [ 'Paul', Validators.required ],
        lastName: [ 'Evans', Validators.required ],
        email: [ 'test@test.com', [ Validators.required, Validators.email ] ],
        gender: [ 'Male', Validators.required ],
        category: [ 'V35-39', Validators.required ],
        certificate: [ 'Gold', Validators.required ],
      },
      { updateOn: 'blur' }
    ),
    this.formBuilder.group(
      {
        race1Distance: [ 'Mile', Validators.required ],
        race1Date: [ '16/04/2019', Validators.required ],
        race1Race: [ 'Magic Mile', Validators.required ],
        race1FinishTimeHours: [ '00', Validators.required ],
        race1FinishTimeMinutes: [ '05', Validators.required ],
        race1FinishTimeSeconds: [ '46', Validators.required ],
      },
      { updateOn: 'blur' }
    ),
    this.formBuilder.group(
      {
        race2Distance: [ '5K', Validators.required ],
        race2Date: [ '12/03/2019', Validators.required ],
        race2Race: [ 'Worcester parkrun', Validators.required ],
        race2FinishTimeHours: [ '00', Validators.required ],
        race2FinishTimeMinutes: [ '19', Validators.required ],
        race2FinishTimeSeconds: [ '45', Validators.required ],
      },
      { updateOn: 'blur' }
    ),
    this.formBuilder.group(
      {
        race3Distance: [ '10K', Validators.required ],
        race3Date: [ '01/02/2019', Validators.required ],
        race3Race: [ 'Telford 10K', Validators.required ],
        race3FinishTimeHours: [ '00', Validators.required ],
        race3FinishTimeMinutes: [ '38', Validators.required ],
        race3FinishTimeSeconds: [ '23', Validators.required ],
      },
      { updateOn: 'blur' }
    ),
  ];

  constructor(private actions$: Actions, private formBuilder: FormBuilder) {
    this.actions$.pipe(ofType(ClubStandardsActionTypes.ClubStandardsClaimStart)).subscribe(() => {
      alert('This feature is not yet available. Please email standards@blackpearjoggers.org.uk to claim a certificate.');
      this.isOpen = true;
    });
  }

  ngOnInit() {}

  onCloseModal() {
    this.isOpen = false;
  }

  onBackButton() {
    if (!this.isFirstPage()) {
      this.currentPage--;
    }
  }

  onNextButton() {
    if (!this.pageIsValid(this.currentPage)) {
      this.showValidation = true;
      return;
    }

    if (!this.isLastPage()) {
      this.currentPage++;

      return;
    }

    if (this.isLastPage()) {
      this.submitClaim();
    }
  }

  submitClaim() {
    // console.log(
    //   this.claimForm.map((page) => {
    //     return page.controls.map((control, value) => {
    //       return control + value;
    //     });
    //   })
    // );
    // console.log(this.claimForm.values(console.log);
    console.log('submitClaim method not implemented.');
  }

  pageIsValid(page: number): boolean {
    return this.claimForm[page - 1].valid;
  }

  isFirstPage(): boolean {
    return this.currentPage === 1;
  }

  isLastPage(): boolean {
    return this.currentPage === this.claimForm.length;
  }
}
