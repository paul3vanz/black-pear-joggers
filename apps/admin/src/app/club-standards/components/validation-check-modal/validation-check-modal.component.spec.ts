import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';

import { ValidationCheckModalComponent } from './validation-check-modal.component';

describe('ValidationCheckModalComponent', () => {
  let component: ValidationCheckModalComponent;
  let fixture: ComponentFixture<ValidationCheckModalComponent>;

  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
      declarations: [ ValidationCheckModalComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(ValidationCheckModalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
