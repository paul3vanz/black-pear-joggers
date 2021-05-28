import { async, TestBed } from '@angular/core/testing';
import { MembershipDataAccessModule } from './membership-data-access.module';

describe('MembershipDataAccessModule', () => {
  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [MembershipDataAccessModule],
    }).compileComponents();
  }));

  it('should create', () => {
    expect(MembershipDataAccessModule).toBeDefined();
  });
});
