import { TestBed, waitForAsync } from '@angular/core/testing';
import { MembershipDataAccessModule } from './membership-data-access.module';

describe('MembershipDataAccessModule', () => {
  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
      imports: [MembershipDataAccessModule],
    }).compileComponents();
  }));

  it('should create', () => {
    expect(MembershipDataAccessModule).toBeDefined();
  });
});
