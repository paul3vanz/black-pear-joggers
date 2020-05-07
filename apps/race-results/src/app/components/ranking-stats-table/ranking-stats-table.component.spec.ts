import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { RankingStatsTableComponent } from './ranking-stats-table.component';

describe('RankingStatsTableComponent', () => {
  let component: RankingStatsTableComponent;
  let fixture: ComponentFixture<RankingStatsTableComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ RankingStatsTableComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(RankingStatsTableComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
