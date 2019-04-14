import { ClubStandardsLoaded } from './club-standards.actions';
import {
  ClubStandardsState,
  Entity,
  initialState,
  clubStandardsReducer
} from './club-standards.reducer';

describe('ClubStandards Reducer', () => {
  const getClubStandardsId = it => it['id'];
  let createClubStandards;

  beforeEach(() => {
    createClubStandards = (id: string, name = ''): Entity => ({
      id,
      name: name || `name-${id}`
    });
  });

  describe('valid ClubStandards actions ', () => {
    it('should return set the list of known ClubStandards', () => {
      const clubStandardss = [
        createClubStandards('PRODUCT-AAA'),
        createClubStandards('PRODUCT-zzz')
      ];
      const action = new ClubStandardsLoaded(clubStandardss);
      const result: ClubStandardsState = clubStandardsReducer(
        initialState,
        action
      );
      const selId: string = getClubStandardsId(result.list[1]);

      expect(result.loaded).toBe(true);
      expect(result.list.length).toBe(2);
      expect(selId).toBe('PRODUCT-zzz');
    });
  });

  describe('unknown action', () => {
    it('should return the initial state', () => {
      const action = {} as any;
      const result = clubStandardsReducer(initialState, action);

      expect(result).toBe(initialState);
    });
  });
});
