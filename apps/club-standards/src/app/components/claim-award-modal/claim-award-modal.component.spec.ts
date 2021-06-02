import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';

import { ClaimAwardModalComponent } from './claim-award-modal.component';

describe('ClaimAwardModalComponent', () => {
  let component: ClaimAwardModalComponent;
  let fixture: ComponentFixture<ClaimAwardModalComponent>;

  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
      declarations: [ ClaimAwardModalComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(ClaimAwardModalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
