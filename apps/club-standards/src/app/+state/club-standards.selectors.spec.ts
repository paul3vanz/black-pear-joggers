import { Entity, ClubStandardsState } from './club-standards.reducer';
import { clubStandardsQuery } from './club-standards.selectors';

describe('ClubStandards Selectors', () => {
  const ERROR_MSG = 'No Error Available';
  const getClubStandardsId = it => it['id'];

  let storeState;

  beforeEach(() => {
    const createClubStandards = (id: string, name = ''): Entity => ({
      id,
      name: name || `name-${id}`
    });
    storeState = {
      clubStandards: {
        list: [
          createClubStandards('PRODUCT-AAA'),
          createClubStandards('PRODUCT-BBB'),
          createClubStandards('PRODUCT-CCC')
        ],
        selectedId: 'PRODUCT-BBB',
        error: ERROR_MSG,
        loaded: true
      }
    };
  });

  describe('ClubStandards Selectors', () => {
    it('getAllClubStandards() should return the list of ClubStandards', () => {
      const results = clubStandardsQuery.getAllClubStandards(storeState);
      const selId = getClubStandardsId(results[1]);

      expect(results.length).toBe(3);
      expect(selId).toBe('PRODUCT-BBB');
    });

    it('getSelectedClubStandards() should return the selected Entity', () => {
      const result = clubStandardsQuery.getSelectedClubStandards(storeState);
      const selId = getClubStandardsId(result);

      expect(selId).toBe('PRODUCT-BBB');
    });

    it("getLoaded() should return the current 'loaded' status", () => {
      const result = clubStandardsQuery.getLoaded(storeState);

      expect(result).toBe(true);
    });

    it("getError() should return the current 'error' storeState", () => {
      const result = clubStandardsQuery.getError(storeState);

      expect(result).toBe(ERROR_MSG);
    });
  });
});
