import { TestBed, waitForAsync } from '@angular/core/testing';
import { SharedPipesModule } from './shared-pipes.module';

describe('SharedPipesModule', () => {
  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
      imports: [SharedPipesModule]
    }).compileComponents();
  }));

  it('should create', () => {
    expect(SharedPipesModule).toBeDefined();
  });
});
