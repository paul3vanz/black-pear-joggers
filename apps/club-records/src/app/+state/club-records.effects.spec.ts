import { TestBed, waitForAsync } from '@angular/core/testing';

import { Observable } from 'rxjs';

import { EffectsModule } from '@ngrx/effects';
import { StoreModule } from '@ngrx/store';
import { provideMockActions } from '@ngrx/effects/testing';

import { NxModule } from '@nrwl/nx';
import { DataPersistence } from '@nrwl/nx';
import { hot } from '@nrwl/nx/testing';

import { ClubRecordsEffects } from './club-records.effects';
import { LoadClubRecords, ClubRecordsLoaded } from './club-records.actions';

describe('ClubRecordsEffects', () => {
  let actions: Observable<any>;
  let effects: ClubRecordsEffects;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [
        NxModule.forRoot(),
        StoreModule.forRoot({}),
        EffectsModule.forRoot([])
      ],
      providers: [
        ClubRecordsEffects,
        DataPersistence,
        provideMockActions(() => actions)
      ]
    });

    effects = TestBed.get(ClubRecordsEffects);
  });

  describe('loadClubRecords$', () => {
    it('should work', () => {
      actions = hot('-a-|', { a: new LoadClubRecords() });
      expect(effects.loadClubRecords$).toBeObservable(
        hot('-a-|', { a: new ClubRecordsLoaded([]) })
      );
    });
  });
});
