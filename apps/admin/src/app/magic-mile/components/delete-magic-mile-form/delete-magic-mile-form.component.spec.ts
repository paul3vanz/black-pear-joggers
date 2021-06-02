import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';

import { DeleteMagicMileFormComponent } from './delete-magic-mile-form.component';

describe('DeleteMagicMileFormComponent', () => {
  let component: DeleteMagicMileFormComponent;
  let fixture: ComponentFixture<DeleteMagicMileFormComponent>;

  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
      declarations: [ DeleteMagicMileFormComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DeleteMagicMileFormComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
