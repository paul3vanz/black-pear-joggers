import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';

import { ClaimStepPersonalDetailsComponent } from './claim-step-personal-details.component';

describe('ClaimStepPersonalDetailsComponent', () => {
  let component: ClaimStepPersonalDetailsComponent;
  let fixture: ComponentFixture<ClaimStepPersonalDetailsComponent>;

  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
      declarations: [ ClaimStepPersonalDetailsComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(ClaimStepPersonalDetailsComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
