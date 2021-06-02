import { TestBed, waitForAsync } from '@angular/core/testing';

import { Observable } from 'rxjs';

import { EffectsModule } from '@ngrx/effects';
import { StoreModule } from '@ngrx/store';
import { provideMockActions } from '@ngrx/effects/testing';

import { NxModule } from '@nrwl/nx';
import { DataPersistence } from '@nrwl/nx';
import { hot } from '@nrwl/nx/testing';

import { MagicMileEffects } from './magic-mile.effects';
import { LoadMagicMile, MagicMileLoaded } from './magic-mile.actions';

describe('MagicMileEffects', () => {
  let actions: Observable<any>;
  let effects: MagicMileEffects;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [
        NxModule.forRoot(),
        StoreModule.forRoot({}),
        EffectsModule.forRoot([])
      ],
      providers: [
        MagicMileEffects,
        DataPersistence,
        provideMockActions(() => actions)
      ]
    });

    effects = TestBed.get(MagicMileEffects);
  });

  describe('loadMagicMile$', () => {
    it('should work', () => {
      actions = hot('-a-|', { a: new LoadMagicMile() });
      expect(effects.loadMagicMile$).toBeObservable(
        hot('-a-|', { a: new MagicMileLoaded([]) })
      );
    });
  });
});
