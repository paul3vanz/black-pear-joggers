import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';

import { RankingStatsTableComponent } from './ranking-stats-table.component';

describe('RankingStatsTableComponent', () => {
  let component: RankingStatsTableComponent;
  let fixture: ComponentFixture<RankingStatsTableComponent>;

  beforeEach(waitForAsync(() => {
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
