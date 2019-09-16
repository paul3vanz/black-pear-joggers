import { Component, Output, EventEmitter } from '@angular/core';
import { FormBuilder, Validators } from '@angular/forms';

import * as moment from 'moment-mini-ts';
import { MagicMileLocation } from 'libs/magic-mile-data-access/src/lib/models/magic-mile-location.model';
import { Athlete } from 'apps/race-results/src/app/models/athlete';
import { Observable, forkJoin } from 'rxjs';
import { MagicMileState } from '../../+state/magic-mile.reducer';
import { Store } from '@ngrx/store';
import { distinctUntilChanged, debounceTime, filter } from 'rxjs/operators';
import { LoadAthletes } from '../../+state/magic-mile.actions';
import { magicMileQuery } from '../../+state/magic-mile.selectors';
import { LoadingState } from 'libs/authentication/src/lib/models/loading-state.model';

@Component({
  selector: 'bpj-record-magic-mile-form',
  templateUrl: './record-magic-mile-form.component.html',
  styleUrls: ['./record-magic-mile-form.component.scss']
})
export class RecordMagicMileFormComponent {
  athletes$: Observable<Athlete[]>;
  athletesLoadingState$: Observable<LoadingState>;
  @Output() submit = new EventEmitter<any>();

  form = this.formBuilder.group({
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
  });

  constructor(
    private formBuilder: FormBuilder,
    private store$: Store<any>
  ) {
    this.athletes$ = this.store$.select(magicMileQuery.getSearchedAthletes);
    this.athletesLoadingState$ = this.store$.select(magicMileQuery.getLoadingState);

    this.form.get('firstName').valueChanges.pipe(
      debounceTime(500),
      distinctUntilChanged(),
      filter((value) => value.length >= 2),
    ).subscribe(() => {
      this.emitAthleteName();
    });

    this.form.get('lastName').valueChanges.pipe(
      debounceTime(500),
      distinctUntilChanged(),
      filter((value) => value.length >= 2),
    ).subscribe(() => {
      this.emitAthleteName();
    });
  }

  onSubmit() {
    console.log('SUBMIT', this.form.value);
    this.submit.emit(this.form.value);
  }

  onChangeTime() {
    this.form.get('predictedTimeParsed').setValue(this.convertTimeToSeconds(this.form.get('predictedTime').value));
    this.form.get('actualTimeParsed').setValue(this.convertTimeToSeconds(this.form.get('actualTime').value));
  }

  emitAthleteName() {
    this.store$.dispatch(new LoadAthletes(
      `${this.form.get('firstName').value} ${this.form.get('lastName').value}`.trim()
    ));
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
