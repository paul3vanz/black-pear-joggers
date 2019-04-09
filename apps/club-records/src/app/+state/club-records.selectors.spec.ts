import { Entity, ClubRecordsState } from './club-records.reducer';
import { clubRecordsQuery } from './club-records.selectors';

describe('ClubRecords Selectors', () => {
  const ERROR_MSG = 'No Error Available';
  const getClubRecordsId = it => it['id'];

  let storeState;

  beforeEach(() => {
    const createClubRecords = (id: string, name = ''): Entity => ({
      id,
      name: name || `name-${id}`
    });
    storeState = {
      clubRecords: {
        list: [
          createClubRecords('PRODUCT-AAA'),
          createClubRecords('PRODUCT-BBB'),
          createClubRecords('PRODUCT-CCC')
        ],
        selectedId: 'PRODUCT-BBB',
        error: ERROR_MSG,
        loaded: true
      }
    };
  });

  describe('ClubRecords Selectors', () => {
    it('getAllClubRecords() should return the list of ClubRecords', () => {
      const results = clubRecordsQuery.getAllClubRecords(storeState);
      const selId = getClubRecordsId(results[1]);

      expect(results.length).toBe(3);
      expect(selId).toBe('PRODUCT-BBB');
    });

    it('getSelectedClubRecords() should return the selected Entity', () => {
      const result = clubRecordsQuery.getSelectedClubRecords(storeState);
      const selId = getClubRecordsId(result);

      expect(selId).toBe('PRODUCT-BBB');
    });

    it("getLoaded() should return the current 'loaded' status", () => {
      const result = clubRecordsQuery.getLoaded(storeState);

      expect(result).toBe(true);
    });

    it("getError() should return the current 'error' storeState", () => {
      const result = clubRecordsQuery.getError(storeState);

      expect(result).toBe(ERROR_MSG);
    });
  });
});
