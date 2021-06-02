import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';

import { ClaimStepCategoryDetailsComponent } from './claim-step-category-details.component';

describe('ClaimStepCategoryDetailsComponent', () => {
  let component: ClaimStepCategoryDetailsComponent;
  let fixture: ComponentFixture<ClaimStepCategoryDetailsComponent>;

  beforeEach(waitForAsync(() => {
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
