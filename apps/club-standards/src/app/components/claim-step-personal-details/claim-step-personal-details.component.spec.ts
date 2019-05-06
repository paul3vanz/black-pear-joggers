import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { ClaimStepPersonalDetailsComponent } from './claim-step-personal-details.component';

describe('ClaimStepPersonalDetailsComponent', () => {
  let component: ClaimStepPersonalDetailsComponent;
  let fixture: ComponentFixture<ClaimStepPersonalDetailsComponent>;

  beforeEach(async(() => {
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
