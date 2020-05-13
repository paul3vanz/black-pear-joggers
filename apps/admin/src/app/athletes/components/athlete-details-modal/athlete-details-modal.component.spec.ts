import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { AthleteDetailsModalComponent } from './athlete-details-modal.component';

describe('AthleteDetailsModalComponent', () => {
  let component: AthleteDetailsModalComponent;
  let fixture: ComponentFixture<AthleteDetailsModalComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ AthleteDetailsModalComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(AthleteDetailsModalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
