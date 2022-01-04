import { TestBed, waitForAsync } from '@angular/core/testing';

import { Observable } from 'rxjs';

import { EffectsModule } from '@ngrx/effects';
import { StoreModule } from '@ngrx/store';
import { provideMockActions } from '@ngrx/effects/testing';

import { NxModule } from '@nrwl/angular';
import { DataPersistence } from '@nrwl/angular';
import { hot } from '@nrwl/angular/testing';

import { ClubStandardsEffects } from './club-standards.effects';
import { LoadClubStandards, ClubStandardsLoaded } from './club-standards.actions';

describe('ClubStandardsEffects', () => {
  let actions: Observable<any>;
  let effects: ClubStandardsEffects;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [NxModule.forRoot(), StoreModule.forRoot({}), EffectsModule.forRoot([])],
      providers: [ClubStandardsEffects, DataPersistence, provideMockActions(() => actions)],
    });

    effects = TestBed.get(ClubStandardsEffects);
  });

  describe('loadClubStandards$', () => {
    it('should work', () => {
      actions = hot('-a-|', { a: new LoadClubStandards() });
      expect(effects.loadClubStandards$).toBeObservable(hot('-a-|', { a: new ClubStandardsLoaded([]) }));
    });
  });
});
