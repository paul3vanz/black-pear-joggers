import { Component, OnInit, Input } from '@angular/core';
import { Actions, ofType } from '@ngrx/effects';
import { ClubStandardsActionTypes, fromClubStandardsActions, ClubStandardsClaimSubmit } from '../../+state/club-standards.actions';
import { FormBuilder, Validators, FormGroup, FormArray } from '@angular/forms';
import { Standard } from '../../models/standard.model';
import { Observable } from 'rxjs';
import { Store } from '@ngrx/store';
import { clubStandardsQuery } from '../../+state/club-standards.selectors';
import { withLatestFrom } from 'rxjs/operators';
import { ClubStandardsService } from '../../services/club-standards.service';

@Component({
  selector: 'bpj-claim-award-modal',
  templateUrl: './claim-award-modal.component.html',
  styleUrls: [ './claim-award-modal.component.scss' ],
})
export class ClaimAwardModalComponent implements OnInit {
  @Input() isOpen = false;

  gender$: Observable<string>;
  category$: Observable<string>;
  standards$: Observable<Standard[]>;

  claimLoading$: Observable<boolean>;
  claimLoaded$: Observable<boolean>;
  claimError$: Observable<boolean>;

  currentStep = 1;
  steps = 3;
  showValidation = false;
  claimForm: FormGroup;

  events: string[] = [ 'Mile', '5K', '10K', 'Half Marathon', 'Marathon' ];
  maximumRaces: number = this.events.length;

  constructor(private actions$: Actions, private formBuilder: FormBuilder, private store$: Store<any>) {
    this.gender$ = this.store$.select(clubStandardsQuery.getActiveGender);
    this.category$ = this.store$.select(clubStandardsQuery.getActiveCategory);
    this.standards$ = this.store$.select(clubStandardsQuery.getAllClubStandards);

    this.claimLoading$ = this.store$.select(clubStandardsQuery.getClaimLoading);
    this.claimLoaded$ = this.store$.select(clubStandardsQuery.getClaimLoaded);
    this.claimError$ = this.store$.select(clubStandardsQuery.getClaimError);

    this.claimForm = this.formBuilder.group({
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

    this.gender$.subscribe((gender) => this.claimForm.patchValue({ categoryDetails: { gender } }, { emitEvent: false }));
    this.category$.subscribe((category) => this.claimForm.patchValue({ categoryDetails: { category } }, { emitEvent: false }));

    this.addRace();

    this.actions$.pipe(ofType(ClubStandardsActionTypes.ClubStandardsClaimStart)).subscribe(() => {
      // alert('This feature is not yet available. Please email standards@blackpearjoggers.org.uk to claim a certificate.');
      this.isOpen = true;
    });
  }

  addRace() {
    const races = <FormArray>this.claimForm.controls['races'];

    if (this.hasMaximumEvents()) {
      return;
    }

    races.push(
      this.formBuilder.group(
        {
          distance: [ '', Validators.required ],
          date: [ '', Validators.required ],
          race: [ '', Validators.required ],
          finishTime: this.formBuilder.group({
            hours: [ 0, Validators.required ],
            minutes: [ 0, Validators.required ],
            seconds: [ 0, Validators.required ],
          }),
          award: [ '', Validators.required ],
        },
        { updateOn: 'change' }
      )
    );
  }

  getDistance(eventName: string): number {
    switch (eventName) {
      case 'Mile':
        return 1609.34;
      case '5K':
        return 5000;
      case '10K':
        return 10000;
      case 'Half Marathon':
        return 21097.5;
      case 'Marathon':
        return 42195;
    }
  }

  finishTimeInSeconds(hours: number, minutes: number, seconds: number) {
    return hours * 3600 + minutes * 60 + seconds;
  }

  ngOnInit() {
    this.claimForm.get('categoryDetails.gender').valueChanges.subscribe((gender) => {
      this.store$.dispatch(new fromClubStandardsActions.ClubStandardsSetGender(gender));
    });

    this.claimForm.get('categoryDetails.category').valueChanges.subscribe((category) => {
      this.store$.dispatch(new fromClubStandardsActions.ClubStandardsSetCategory(category));
    });

    this.races.valueChanges.pipe(withLatestFrom(this.standards$)).subscribe(([ newValue, standards ]) => {
      this.races.controls.forEach((race: FormGroup) => {
        const event = race.get('distance').value;
        const hours = +race.get('finishTime.hours').value;
        const minutes = +race.get('finishTime.minutes').value;
        const seconds = +race.get('finishTime.seconds').value;
        const finishTimeInSeconds = this.finishTimeInSeconds(hours, minutes, seconds);

        const awardOrder = { Bronze: 1, Silver: 2, Gold: 3, Platinum: 4 };

        const eventAward =
          finishTimeInSeconds > 0
            ? standards
                .filter((standard) => standard.event === event)
                .filter((standard) => Number(standard.time_parsed) >= finishTimeInSeconds)
                .sort((value1, value2) => {
                  return awardOrder[value1.name] < awardOrder[value2.name] ? 1 : -1;
                })
                .shift()
            : null;

        race.controls['award'].patchValue(eventAward ? eventAward['name'] : '', { emitEvent: false });
      });
    });
  }

  get races() {
    return <FormArray>this.claimForm.get('races');
  }

  onCloseModal() {
    this.isOpen = false;
  }

  previousStep() {
    if (this.currentStep > 1) {
      this.currentStep--;
    }
  }

  nextStep(stepComplete: boolean) {
    console.log(this.currentStep, stepComplete);
    if (stepComplete) {
      this.showValidation = false;
    } else {
      this.showValidation = true;

      return;
    }

    if (this.currentStep < this.steps) {
      this.currentStep++;
    } else {
      this.submitClaim();
    }
  }

  submitClaim() {
    this.store$.dispatch(new ClubStandardsClaimSubmit(this.claimForm.value));
  }

  stepIsValid(step: string): boolean {
    return this.claimForm.controls[step].valid;
  }

  hasEnoughEvents() {
    const races = <FormArray>this.claimForm.controls['races'];

    return races.length >= 3;
  }

  hasMaximumEvents() {
    const races = <FormArray>this.claimForm.controls['races'];

    return races.length === this.maximumRaces;
  }

  onAddRace() {
    this.addRace();
  }
}
