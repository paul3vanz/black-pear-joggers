import { TestBed } from '@angular/core/testing';

import { ClubStandardsService } from './club-standards.service';

describe('ClubStandardsService', () => {
  beforeEach(() => TestBed.configureTestingModule({}));

  it('should be created', () => {
    const service: ClubStandardsService = TestBed.get(ClubStandardsService);
    expect(service).toBeTruthy();
  });
});
