import * as moment from 'moment-mini-ts';

import { Actions, ofType } from '@ngrx/effects';
import { Component, ElementRef, EventEmitter, Output, ViewChild } from '@angular/core';
import { FormBuilder, Validators } from '@angular/forms';
import { Observable, forkJoin } from 'rxjs';
import { createResultSuccess, magicMileActions, magicMileQuery } from '@black-pear-joggers/magic-mile-data-access';
import { debounceTime, distinctUntilChanged, filter } from 'rxjs/operators';

import { Athlete } from 'apps/race-results/src/app/models/athlete';
import { LoadingState } from '@black-pear-joggers/authentication';
import { MagicMileLocation } from 'libs/magic-mile-data-access/src/lib/models/magic-mile-location.model';
import { Store } from '@ngrx/store';
import { ToastService } from 'libs/shared-components/src/lib/services/toast.service';

@Component({
  selector: 'bpj-record-magic-mile-form',
  templateUrl: './record-magic-mile-form.component.html',
  styleUrls: ['./record-magic-mile-form.component.scss'],
})
export class RecordMagicMileFormComponent {
  athletes$: Observable<Athlete[]>;
  callState$: Observable<LoadingState>;
  showErrors = false;

  @Output() create = new EventEmitter<any>();

  @ViewChild('firstName') firstName: ElementRef<HTMLInputElement>;

  initialFormState = {
    date: [moment().format('YYYY-MM-DD'), Validators.required],
    location: [this.getDefaultLocation(), Validators.required],
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

  keysResetOnSave = ['athleteId', 'firstName', 'lastName', 'gender', 'category'];

  form = this.formBuilder.group(this.initialFormState);

  constructor(private formBuilder: FormBuilder, private store$: Store<any>, private actions$: Actions, private toastService: ToastService) {
    this.callState$ = this.store$.select(magicMileQuery.getCallState);
    this.athletes$ = this.store$.select(magicMileQuery.getAthletes);

    this.actions$.pipe(ofType(createResultSuccess)).subscribe(() => {
      this.toastService.pushMessage('Record created');

      this.keysResetOnSave.forEach((key) => {
        this.form.controls[key].reset(this.initialFormState[key][0]);
      });

      this.firstName.nativeElement.focus();

      this.showErrors = false;
    });

    this.form
      .get('firstName')
      .valueChanges.pipe(
        debounceTime(500),
        distinctUntilChanged(),
        filter((value) => value && value.length >= 2)
      )
      .subscribe(() => {
        this.emitAthleteName();
      });

    this.form
      .get('lastName')
      .valueChanges.pipe(
        debounceTime(500),
        distinctUntilChanged(),
        filter((value) => value && value.length >= 2)
      )
      .subscribe(() => {
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

  onChangePredictedTime() {
    this.form.get('actualTime').setValue(this.form.get('predictedTime').value);
    this.updateParsedTimeValues();
  }

  onChangeActualTime() {
    this.updateParsedTimeValues();
  }

  updateParsedTimeValues() {
    this.form.get('predictedTimeParsed').setValue(this.convertTimeToSeconds(this.form.get('predictedTime').value));
    this.form.get('actualTimeParsed').setValue(this.convertTimeToSeconds(this.form.get('actualTime').value));
  }

  emitAthleteName() {
    this.store$.dispatch(
      magicMileActions.searchAthletes({
        name: `${this.form.get('firstName').value} ${this.form.get('lastName').value}`.trim(),
      })
    );
  }

  onSelectAthlete(athlete: Athlete) {
    this.form.patchValue({
      athleteId: athlete.id,
      firstName: athlete.first_name,
      lastName: athlete.last_name,
      gender: athlete.gender,
      category: athlete.category,
    });
  }

  convertTimeToSeconds(timeString: string) {
    return timeString ? moment.duration(`00:${timeString}`).asSeconds() : null;
  }

  getDefaultLocation() {
    return moment().isoWeekday() === 1 // Monday
      ? MagicMileLocation.GRANDSTAND
      : MagicMileLocation.DIGLIS;
  }
}
