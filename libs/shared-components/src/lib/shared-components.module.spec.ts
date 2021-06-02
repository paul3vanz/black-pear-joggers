import { TestBed, waitForAsync } from '@angular/core/testing';
import { SharedComponentsModule } from './shared-components.module';

describe('SharedComponentsModule', () => {
  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
      imports: [SharedComponentsModule]
    }).compileComponents();
  }));

  it('should create', () => {
    expect(SharedComponentsModule).toBeDefined();
  });
});
