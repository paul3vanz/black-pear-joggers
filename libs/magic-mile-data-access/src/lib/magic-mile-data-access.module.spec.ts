import { async, TestBed } from '@angular/core/testing';
import { MagicMileDataAccessModule } from './magic-mile-data-access.module';

describe('MagicMileDataAccessModule', () => {
  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [MagicMileDataAccessModule]
    }).compileComponents();
  }));

  it('should create', () => {
    expect(MagicMileDataAccessModule).toBeDefined();
  });
});
