import { SearchLoaded } from './search.actions';
import {
  SearchState,
  Entity,
  initialState,
  searchReducer
} from './search.reducer';

describe('Search Reducer', () => {
  const getSearchId = it => it['id'];
  let createSearch;

  beforeEach(() => {
    createSearch = (id: string, name = ''): Entity => ({
      id,
      name: name || `name-${id}`
    });
  });

  describe('valid Search actions ', () => {
    it('should return set the list of known Search', () => {
      const searchs = [
        createSearch('PRODUCT-AAA'),
        createSearch('PRODUCT-zzz')
      ];
      const action = new SearchLoaded(searchs);
      const result: SearchState = searchReducer(initialState, action);
      const selId: string = getSearchId(result.list[1]);

      expect(result.loaded).toBe(true);
      expect(result.list.length).toBe(2);
      expect(selId).toBe('PRODUCT-zzz');
    });
  });

  describe('unknown action', () => {
    it('should return the initial state', () => {
      const action = {} as any;
      const result = searchReducer(initialState, action);

      expect(result).toBe(initialState);
    });
  });
});
