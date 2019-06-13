import { TestBed } from '@angular/core/testing';

import { AwardClaimService } from './award-claim.service';

describe('AwardClaimService', () => {
  beforeEach(() => TestBed.configureTestingModule({}));

  it('should be created', () => {
    const service: AwardClaimService = TestBed.get(AwardClaimService);
    expect(service).toBeTruthy();
  });
});
