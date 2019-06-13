import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { ClubStandardsPageComponent } from './club-standards-page.component';

describe('ClubStandardsPageComponent', () => {
  let component: ClubStandardsPageComponent;
  let fixture: ComponentFixture<ClubStandardsPageComponent>;

  beforeEach(async(() => {
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
