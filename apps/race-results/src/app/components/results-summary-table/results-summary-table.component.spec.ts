import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { ResultsSummaryTableComponent } from './results-summary-table.component';

describe('ResultsSummaryTableComponent', () => {
  let component: ResultsSummaryTableComponent;
  let fixture: ComponentFixture<ResultsSummaryTableComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ ResultsSummaryTableComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(ResultsSummaryTableComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should be created', () => {
    expect(component).toBeTruthy();
  });
});
