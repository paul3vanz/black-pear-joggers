import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { AthleteSearchResultsComponent } from './athlete-search-results.component';

describe('AthleteSearchResultsComponent', () => {
  let component: AthleteSearchResultsComponent;
  let fixture: ComponentFixture<AthleteSearchResultsComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ AthleteSearchResultsComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(AthleteSearchResultsComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
