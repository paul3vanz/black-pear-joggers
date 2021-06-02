import { TestBed, waitForAsync } from '@angular/core/testing';
import { ClubStandardsDataAccessModule } from './club-standards-data-access.module';

describe('ClubStandardsDataAccessModule', () => {
  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
      imports: [ClubStandardsDataAccessModule]
    }).compileComponents();
  }));

  it('should create', () => {
    expect(ClubStandardsDataAccessModule).toBeDefined();
  });
});
