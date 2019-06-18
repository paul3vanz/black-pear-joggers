import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { ValidationCheckModalComponent } from './validation-check-modal.component';

describe('ValidationCheckModalComponent', () => {
  let component: ValidationCheckModalComponent;
  let fixture: ComponentFixture<ValidationCheckModalComponent>;

  beforeEach(async(() => {
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
