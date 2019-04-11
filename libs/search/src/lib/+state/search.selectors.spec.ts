import { Entity, SearchState } from './search.reducer';
import { searchQuery } from './search.selectors';

describe('Search Selectors', () => {
  const ERROR_MSG = 'No Error Available';
  const getSearchId = it => it['id'];

  let storeState;

  beforeEach(() => {
    const createSearch = (id: string, name = ''): Entity => ({
      id,
      name: name || `name-${id}`
    });
    storeState = {
      search: {
        list: [
          createSearch('PRODUCT-AAA'),
          createSearch('PRODUCT-BBB'),
          createSearch('PRODUCT-CCC')
        ],
        selectedId: 'PRODUCT-BBB',
        error: ERROR_MSG,
        loaded: true
      }
    };
  });

  describe('Search Selectors', () => {
    it('getAllSearch() should return the list of Search', () => {
      const results = searchQuery.getAllSearch(storeState);
      const selId = getSearchId(results[1]);

      expect(results.length).toBe(3);
      expect(selId).toBe('PRODUCT-BBB');
    });

    it('getSelectedSearch() should return the selected Entity', () => {
      const result = searchQuery.getSelectedSearch(storeState);
      const selId = getSearchId(result);

      expect(selId).toBe('PRODUCT-BBB');
    });

    it("getLoaded() should return the current 'loaded' status", () => {
      const result = searchQuery.getLoaded(storeState);

      expect(result).toBe(true);
    });

    it("getError() should return the current 'error' storeState", () => {
      const result = searchQuery.getError(storeState);

      expect(result).toBe(ERROR_MSG);
    });
  });
});
