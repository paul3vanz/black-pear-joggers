import { Component } from '@angular/core';
import { FormBuilder, Validators } from '@angular/forms';

import * as moment from 'moment-mini-ts';
import { MagicMileLocation } from 'libs/magic-mile-data-access/src/lib/models/magic-mile-location.model';

@Component({
  selector: 'bpj-record-magic-mile-form',
  templateUrl: './record-magic-mile-form.component.html',
  styleUrls: ['./record-magic-mile-form.component.scss']
})
export class RecordMagicMileFormComponent {
  form = this.formBuilder.group({
    date: [ moment().format('YYYY-MM-DD'), Validators.required ],
    location: [ this.defaultLocation(), Validators.required ],
    athleteId: [],
    firstName: ['', Validators.required],
    lastName: ['', Validators.required],
    gender: ['M'],
    category: ['SEN'],
    predictedTime: ['', Validators.required],
    actualTime: ['', Validators.required],
    predictedTimeParsed: ['', Validators.required],
    actualTimeParsed: ['', Validators.required],
  });

  constructor(private formBuilder: FormBuilder) { }

  onSubmit() {
    console.log('SUBMIT', this.form.value);
  }

  onChangeTime() {
    this.form.get('predictedTimeParsed').setValue(this.convertTimeToSeconds(this.form.get('predictedTime').value));
    this.form.get('actualTimeParsed').setValue(this.convertTimeToSeconds(this.form.get('actualTime').value));
  }

  convertTimeToSeconds(timeString: string) {
    return timeString
      ? moment.duration(`00:${timeString}`).asSeconds()
      : null;
  }

  defaultLocation() {
    return moment().isoWeekday() === 2
      ? MagicMileLocation.DIGLIS
      : MagicMileLocation.GRANDSTAND;
  }
}
