import { TestBed, waitForAsync } from '@angular/core/testing';
import { SearchModule } from './search.module';

describe('SearchModule', () => {
  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
      imports: [SearchModule]
    }).compileComponents();
  }));

  it('should create', () => {
    expect(SearchModule).toBeDefined();
  });
});
