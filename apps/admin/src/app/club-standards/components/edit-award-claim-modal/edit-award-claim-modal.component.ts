import { Component, OnInit, Input } from '@angular/core';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';

import { AwardClaim } from '@black-pear-joggers/club-standards-data-access';

@Component({
  selector: 'bpj-edit-award-claim-modal',
  templateUrl: './edit-award-claim-modal.component.html',
  styleUrls: [ './edit-award-claim-modal.component.scss' ],
})
export class EditAwardClaimModalComponent implements OnInit {
  @Input() awardClaim: AwardClaim;
  @Input() form: FormGroup;

  constructor(private formBuilder: FormBuilder) {
      this.form = this.formBuilder.group({
        categoryDetails: this.formBuilder.group({
          gender: [ '', Validators.required ],
          category: [ '', Validators.required ],
          certificate: [ '', Validators.required ],
        }),
        races: this.formBuilder.array([]),
        personalDetails: this.formBuilder.group({
          firstName: [ '', Validators.required ],
          lastName: [ '', Validators.required ],
          email: [ '', [ Validators.required, Validators.email ] ],
        }),
      });
  }

    ngOnInit() {
        this.form.patchValue({
            categoryDetails: {
                gender: this.awardClaim.gender,
                category: this.awardClaim.category,
                certificate: this.awardClaim.award,
            },
            personalDetails: {
                firstName: this.awardClaim.firstName,
                lastName: this.awardClaim.lastName,
                email: this.awardClaim.email,
            },
        });
    }
}
