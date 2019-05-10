import { TestBed } from '@angular/core/testing';

import { MagicMileService } from './magic-mile.service';

describe('MagicMileService', () => {
  beforeEach(() => TestBed.configureTestingModule({}));

  it('should be created', () => {
    const service: MagicMileService = TestBed.get(MagicMileService);
    expect(service).toBeTruthy();
  });
});
