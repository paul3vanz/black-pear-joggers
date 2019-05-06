import { Component, Input } from '@angular/core';
import { FormGroup } from '@angular/forms';

@Component({
  selector: 'bpj-claim-step-category-details',
  templateUrl: './claim-step-category-details.component.html',
  styleUrls: [ './claim-step-category-details.component.scss' ],
})
export class ClaimStepCategoryDetailsComponent {
  @Input() form: FormGroup;
}
