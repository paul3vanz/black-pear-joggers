import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { RecordMagicMileFormComponent } from './record-magic-mile-form.component';

describe('RecordMagicMileFormComponent', () => {
  let component: RecordMagicMileFormComponent;
  let fixture: ComponentFixture<RecordMagicMileFormComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ RecordMagicMileFormComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(RecordMagicMileFormComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
