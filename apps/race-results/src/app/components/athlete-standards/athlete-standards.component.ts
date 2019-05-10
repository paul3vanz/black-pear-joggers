import { Component, Input } from '@angular/core';

import { Athlete } from '../../models/athlete';

@Component({
  selector: 'bpj-athlete-standards',
  templateUrl: './athlete-standards.component.html',
  styleUrls: [ './athlete-standards.component.css' ],
})
export class AthleteStandardsComponent {
  @Input() athlete: Athlete;
  @Input() loading: boolean;
  @Input() standards: any;
}
