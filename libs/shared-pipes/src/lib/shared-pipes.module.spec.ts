import { async, TestBed } from '@angular/core/testing';
import { SharedPipesModule } from './shared-pipes.module';

describe('SharedPipesModule', () => {
  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [SharedPipesModule]
    }).compileComponents();
  }));

  it('should create', () => {
    expect(SharedPipesModule).toBeDefined();
  });
});
