import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { ClaimStepRacesComponent } from './claim-step-races.component';

describe('ClaimStepRacesComponent', () => {
  let component: ClaimStepRacesComponent;
  let fixture: ComponentFixture<ClaimStepRacesComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ ClaimStepRacesComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(ClaimStepRacesComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
