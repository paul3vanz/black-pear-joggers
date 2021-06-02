import { TestBed, waitForAsync } from '@angular/core/testing';
import { RaceResultsDataAccessModule } from './race-results-data-access.module';

describe('RaceResultsDataAccessModule', () => {
  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
      imports: [RaceResultsDataAccessModule]
    }).compileComponents();
  }));

  it('should create', () => {
    expect(RaceResultsDataAccessModule).toBeDefined();
  });
});
