import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';

import { MembershipsPageComponent } from './memberships-page.component';

describe('MembershipsPageComponent', () => {
  let component: MembershipsPageComponent;
  let fixture: ComponentFixture<MembershipsPageComponent>;

  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
      declarations: [ MembershipsPageComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(MembershipsPageComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
