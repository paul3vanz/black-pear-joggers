import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';

import { ClubStandardsPageComponent } from './club-standards-page.component';

describe('ClubStandardsPageComponent', () => {
  let component: ClubStandardsPageComponent;
  let fixture: ComponentFixture<ClubStandardsPageComponent>;

  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
      declarations: [ ClubStandardsPageComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(ClubStandardsPageComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
