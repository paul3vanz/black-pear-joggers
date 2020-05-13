import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { AthletesTableComponent } from './athletes-table.component';

describe('AthletesTableComponent', () => {
  let component: AthletesTableComponent;
  let fixture: ComponentFixture<AthletesTableComponent>;

  beforeEach(async(() => {
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
