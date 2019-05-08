import { async, TestBed } from '@angular/core/testing';
import { ClubStandardsDataAccessModule } from './club-standards-data-access.module';

describe('ClubStandardsDataAccessModule', () => {
  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [ClubStandardsDataAccessModule]
    }).compileComponents();
  }));

  it('should create', () => {
    expect(ClubStandardsDataAccessModule).toBeDefined();
  });
});
