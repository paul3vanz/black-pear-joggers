import { async, TestBed } from '@angular/core/testing';
import { RaceResultsDataAccessModule } from './race-results-data-access.module';

describe('RaceResultsDataAccessModule', () => {
  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [RaceResultsDataAccessModule]
    }).compileComponents();
  }));

  it('should create', () => {
    expect(RaceResultsDataAccessModule).toBeDefined();
  });
});
