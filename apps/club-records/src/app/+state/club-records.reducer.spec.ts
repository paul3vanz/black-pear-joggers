import { ClubRecordsLoaded } from './club-records.actions';
import {
  ClubRecordsState,
  Entity,
  initialState,
  clubRecordsReducer
} from './club-records.reducer';

describe('ClubRecords Reducer', () => {
  const getClubRecordsId = it => it['id'];
  let createClubRecords;

  beforeEach(() => {
    createClubRecords = (id: string, name = ''): Entity => ({
      id,
      name: name || `name-${id}`
    });
  });

  describe('valid ClubRecords actions ', () => {
    it('should return set the list of known ClubRecords', () => {
      const clubRecordss = [
        createClubRecords('PRODUCT-AAA'),
        createClubRecords('PRODUCT-zzz')
      ];
      const action = new ClubRecordsLoaded(clubRecordss);
      const result: ClubRecordsState = clubRecordsReducer(initialState, action);
      const selId: string = getClubRecordsId(result.list[1]);

      expect(result.loaded).toBe(true);
      expect(result.list.length).toBe(2);
      expect(selId).toBe('PRODUCT-zzz');
    });
  });

  describe('unknown action', () => {
    it('should return the initial state', () => {
      const action = {} as any;
      const result = clubRecordsReducer(initialState, action);

      expect(result).toBe(initialState);
    });
  });
});
