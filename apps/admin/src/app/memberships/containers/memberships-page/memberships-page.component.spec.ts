import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { MembershipsPageComponent } from './memberships-page.component';

describe('MembershipsPageComponent', () => {
  let component: MembershipsPageComponent;
  let fixture: ComponentFixture<MembershipsPageComponent>;

  beforeEach(async(() => {
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
