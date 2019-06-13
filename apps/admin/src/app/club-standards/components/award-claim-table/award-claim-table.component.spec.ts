import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { AwardClaimTableComponent } from './award-claim-table.component';

describe('AwardClaimTableComponent', () => {
  let component: AwardClaimTableComponent;
  let fixture: ComponentFixture<AwardClaimTableComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ AwardClaimTableComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(AwardClaimTableComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
