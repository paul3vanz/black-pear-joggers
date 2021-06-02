import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';

import { AthletesPageComponent } from './athletes-page.component';

describe('AthletesPageComponent', () => {
  let component: AthletesPageComponent;
  let fixture: ComponentFixture<AthletesPageComponent>;

  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
      declarations: [ AthletesPageComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(AthletesPageComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
