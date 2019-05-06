import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { ClaimStepCategoryDetailsComponent } from './claim-step-category-details.component';

describe('ClaimStepCategoryDetailsComponent', () => {
  let component: ClaimStepCategoryDetailsComponent;
  let fixture: ComponentFixture<ClaimStepCategoryDetailsComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ ClaimStepCategoryDetailsComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(ClaimStepCategoryDetailsComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
