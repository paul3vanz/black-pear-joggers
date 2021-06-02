import { TestBed, waitForAsync } from '@angular/core/testing';
import { ClubRecordsDataAccessModule } from './club-records-data-access.module';

describe('ClubRecordsDataAccessModule', () => {
  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
      imports: [ClubRecordsDataAccessModule]
    }).compileComponents();
  }));

  it('should create', () => {
    expect(ClubRecordsDataAccessModule).toBeDefined();
  });
});
