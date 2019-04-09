import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { ClubRecordsTableComponent } from './club-records-table.component';

describe('ClubRecordsTableComponent', () => {
  let component: ClubRecordsTableComponent;
  let fixture: ComponentFixture<ClubRecordsTableComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ClubRecordsTableComponent]
    }).compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(ClubRecordsTableComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
