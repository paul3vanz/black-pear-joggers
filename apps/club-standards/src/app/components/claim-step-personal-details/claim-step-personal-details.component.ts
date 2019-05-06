import { Component, Input } from '@angular/core';
import { FormGroup } from '@angular/forms';

@Component({
  selector: 'bpj-claim-step-personal-details',
  templateUrl: './claim-step-personal-details.component.html',
  styleUrls: [ './claim-step-personal-details.component.scss' ],
})
export class ClaimStepPersonalDetailsComponent {
  @Input() form: FormGroup;
}
