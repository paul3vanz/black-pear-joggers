import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { StandardsFormComponent } from './standards-form.component';

describe('StandardsFormComponent', () => {
  let component: StandardsFormComponent;
  let fixture: ComponentFixture<StandardsFormComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ StandardsFormComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(StandardsFormComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
