import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';

import { AthletesTableComponent } from './athletes-table.component';

describe('AthletesTableComponent', () => {
  let component: AthletesTableComponent;
  let fixture: ComponentFixture<AthletesTableComponent>;

  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
      declarations: [ AthletesTableComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(AthletesTableComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
