import { Component, Output, EventEmitter } from '@angular/core';
import { FormBuilder, Validators } from '@angular/forms';

import * as moment from 'moment-mini-ts';
import { MagicMileLocation } from 'libs/magic-mile-data-access/src/lib/models/magic-mile-location.model';
import { Athlete } from 'apps/race-results/src/app/models/athlete';
import { Observable } from 'rxjs';
import { Store } from '@ngrx/store';
import { distinctUntilChanged, debounceTime, filter } from 'rxjs/operators';
import { LoadingState } from 'libs/authentication/src/lib/models/loading-state.model';
import { magicMileQuery, createResultSuccess } from '@black-pear-joggers/magic-mile-data-access';
import { Actions, ofType } from '@ngrx/effects';

@Component({
  selector: 'bpj-record-magic-mile-form',
  templateUrl: './record-magic-mile-form.component.html',
  styleUrls: ['./record-magic-mile-form.component.scss']
})
export class RecordMagicMileFormComponent {
  athletes$: Observable<Athlete[]>;
  callState$: Observable<LoadingState>;
  showErrors = false;

  @Output() create = new EventEmitter<any>();

  initialFormState = {
    date: [ moment().format('YYYY-MM-DD'), Validators.required ],
    location: [ this.getDefaultLocation(), Validators.required ],
    athleteId: [],
    firstName: ['', Validators.required],
    lastName: ['', Validators.required],
    gender: ['M'],
    category: ['SEN'],
    predictedTime: ['', Validators.required],
    actualTime: ['', Validators.required],
    predictedTimeParsed: ['', Validators.required],
    actualTimeParsed: ['', Validators.required],
  };

  form = this.formBuilder.group(this.initialFormState);

  constructor(
    private formBuilder: FormBuilder,
    private store$: Store<any>,
    private actions$: Actions
  ) {
    this.callState$ = this.store$.select(magicMileQuery.getCallState);

    this.actions$.pipe(ofType(createResultSuccess)).subscribe(() => {
      const formDefault = {};

      Object.keys(this.initialFormState).forEach((key) => {
        formDefault[key] = this.initialFormState[key][0];
      });

      this.form.reset(formDefault);
      this.showErrors = false;
    });

    this.form.get('firstName').valueChanges.pipe(
      debounceTime(500),
      distinctUntilChanged(),
      filter((value) => value && value.length >= 2),
    ).subscribe(() => {
      this.emitAthleteName();
    });

    this.form.get('lastName').valueChanges.pipe(
      debounceTime(500),
      distinctUntilChanged(),
      filter((value) => value && value.length >= 2),
    ).subscribe(() => {
      this.emitAthleteName();
    });
  }

  onSubmit() {

    if (this.form.valid) {
      this.create.emit(this.form.value);
    } else {
      this.showErrors = true;
    }
  }

  onChangeTime() {
    this.form.get('predictedTimeParsed').setValue(this.convertTimeToSeconds(this.form.get('predictedTime').value));
    this.form.get('actualTimeParsed').setValue(this.convertTimeToSeconds(this.form.get('actualTime').value));
  }

  emitAthleteName() {
    // this.store$.dispatch(new LoadAthletes(
    //   `${this.form.get('firstName').value} ${this.form.get('lastName').value}`.trim()
    // ));
  }

  onSelectAthlete(athlete: Athlete) {
    this.form.patchValue({
      athleteId: athlete.athlete_id,
      firstName: athlete.first_name,
      lastName: athlete.last_name,
      gender: athlete.gender,
      category: athlete.category,
    });
  }

  convertTimeToSeconds(timeString: string) {
    return timeString
      ? moment.duration(`00:${timeString}`).asSeconds()
      : null;
  }

  getDefaultLocation() {
    return moment().isoWeekday() === 1 // Monday
      ? MagicMileLocation.GRANDSTAND
      : MagicMileLocation.DIGLIS;
  }
}
