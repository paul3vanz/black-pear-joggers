import { TestBed } from '@angular/core/testing';

import { ClubRecordsService } from './club-records.service';

describe('ClubRecordsService', () => {
  beforeEach(() => TestBed.configureTestingModule({}));

  it('should be created', () => {
    const service: ClubRecordsService = TestBed.get(ClubRecordsService);
    expect(service).toBeTruthy();
  });
});
