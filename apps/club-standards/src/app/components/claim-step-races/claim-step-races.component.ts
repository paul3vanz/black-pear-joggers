import { Component, Input, EventEmitter, Output } from '@angular/core';
import { FormGroup } from '@angular/forms';

@Component({
  selector: 'bpj-claim-step-races',
  templateUrl: './claim-step-races.component.html',
  styleUrls: [ './claim-step-races.component.scss' ],
})
export class ClaimStepRacesComponent {
  @Input() form: FormGroup;
  @Output() addRace = new EventEmitter();

  onAddRace() {
    this.addRace.emit();
  }
}
