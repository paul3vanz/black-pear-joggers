import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';

import { ViewRacesModalComponent } from './view-races-modal.component';

describe('ViewRacesModalComponent', () => {
  let component: ViewRacesModalComponent;
  let fixture: ComponentFixture<ViewRacesModalComponent>;

  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
      declarations: [ ViewRacesModalComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(ViewRacesModalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
