import { Entity, MagicMileState } from './magic-mile.reducer';
import { magicMileQuery } from './magic-mile.selectors';

describe('MagicMile Selectors', () => {
  const ERROR_MSG = 'No Error Available';
  const getMagicMileId = it => it['id'];

  let storeState;

  beforeEach(() => {
    const createMagicMile = (id: string, name = ''): Entity => ({
      id,
      name: name || `name-${id}`
    });
    storeState = {
      magicMile: {
        list: [
          createMagicMile('PRODUCT-AAA'),
          createMagicMile('PRODUCT-BBB'),
          createMagicMile('PRODUCT-CCC')
        ],
        selectedId: 'PRODUCT-BBB',
        error: ERROR_MSG,
        loaded: true
      }
    };
  });

  describe('MagicMile Selectors', () => {
    it('getAllMagicMile() should return the list of MagicMile', () => {
      const results = magicMileQuery.getAllMagicMile(storeState);
      const selId = getMagicMileId(results[1]);

      expect(results.length).toBe(3);
      expect(selId).toBe('PRODUCT-BBB');
    });

    it('getSelectedMagicMile() should return the selected Entity', () => {
      const result = magicMileQuery.getSelectedMagicMile(storeState);
      const selId = getMagicMileId(result);

      expect(selId).toBe('PRODUCT-BBB');
    });

    it("getLoaded() should return the current 'loaded' status", () => {
      const result = magicMileQuery.getLoaded(storeState);

      expect(result).toBe(true);
    });

    it("getError() should return the current 'error' storeState", () => {
      const result = magicMileQuery.getError(storeState);

      expect(result).toBe(ERROR_MSG);
    });
  });
});
