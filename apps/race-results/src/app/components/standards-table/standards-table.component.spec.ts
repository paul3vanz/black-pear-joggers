import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';

import { StandardsTableComponent } from './standards-table.component';

describe('StandardsTableComponent', () => {
  let component: StandardsTableComponent;
  let fixture: ComponentFixture<StandardsTableComponent>;

  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
      declarations: [ StandardsTableComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(StandardsTableComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should be created', () => {
    expect(component).toBeTruthy();
  });
});
