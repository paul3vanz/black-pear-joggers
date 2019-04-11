import { TestBed, async } from '@angular/core/testing';

import { Observable } from 'rxjs';

import { EffectsModule } from '@ngrx/effects';
import { StoreModule } from '@ngrx/store';
import { provideMockActions } from '@ngrx/effects/testing';

import { NxModule } from '@nrwl/nx';
import { DataPersistence } from '@nrwl/nx';
import { hot } from '@nrwl/nx/testing';

import { SearchEffects } from './search.effects';
import { LoadSearch, SearchLoaded } from './search.actions';

describe('SearchEffects', () => {
  let actions: Observable<any>;
  let effects: SearchEffects;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [
        NxModule.forRoot(),
        StoreModule.forRoot({}),
        EffectsModule.forRoot([])
      ],
      providers: [
        SearchEffects,
        DataPersistence,
        provideMockActions(() => actions)
      ]
    });

    effects = TestBed.get(SearchEffects);
  });

  describe('loadSearch$', () => {
    it('should work', () => {
      actions = hot('-a-|', { a: new LoadSearch() });
      expect(effects.loadSearch$).toBeObservable(
        hot('-a-|', { a: new SearchLoaded([]) })
      );
    });
  });
});
