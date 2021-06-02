import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';

import { MagicMilePageComponent } from './magic-mile-page.component';

describe('MagicMilePageComponent', () => {
  let component: MagicMilePageComponent;
  let fixture: ComponentFixture<MagicMilePageComponent>;

  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
      declarations: [ MagicMilePageComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(MagicMilePageComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
