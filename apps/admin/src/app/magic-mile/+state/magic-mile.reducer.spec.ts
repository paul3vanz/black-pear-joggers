import { MagicMileLoaded } from './magic-mile.actions';
import {
  MagicMileState,
  Entity,
  initialState,
  magicMileReducer
} from './magic-mile.reducer';

describe('MagicMile Reducer', () => {
  const getMagicMileId = it => it['id'];
  let createMagicMile;

  beforeEach(() => {
    createMagicMile = (id: string, name = ''): Entity => ({
      id,
      name: name || `name-${id}`
    });
  });

  describe('valid MagicMile actions ', () => {
    it('should return set the list of known MagicMile', () => {
      const magicMiles = [
        createMagicMile('PRODUCT-AAA'),
        createMagicMile('PRODUCT-zzz')
      ];
      const action = new MagicMileLoaded(magicMiles);
      const result: MagicMileState = magicMileReducer(initialState, action);
      const selId: string = getMagicMileId(result.list[1]);

      expect(result.loaded).toBe(true);
      expect(result.list.length).toBe(2);
      expect(selId).toBe('PRODUCT-zzz');
    });
  });

  describe('unknown action', () => {
    it('should return the initial state', () => {
      const action = {} as any;
      const result = magicMileReducer(initialState, action);

      expect(result).toBe(initialState);
    });
  });
});
