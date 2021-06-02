import { TestBed, waitForAsync } from '@angular/core/testing';
import { MagicMileDataAccessModule } from './magic-mile-data-access.module';

describe('MagicMileDataAccessModule', () => {
  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
      imports: [MagicMileDataAccessModule]
    }).compileComponents();
  }));

  it('should create', () => {
    expect(MagicMileDataAccessModule).toBeDefined();
  });
});
