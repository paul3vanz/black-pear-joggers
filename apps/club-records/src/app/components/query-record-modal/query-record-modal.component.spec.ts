import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';

import { QueryRecordModalComponent } from './query-record-modal.component';

describe('QueryRecordModalComponent', () => {
  let component: QueryRecordModalComponent;
  let fixture: ComponentFixture<QueryRecordModalComponent>;

  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
      declarations: [ QueryRecordModalComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(QueryRecordModalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
