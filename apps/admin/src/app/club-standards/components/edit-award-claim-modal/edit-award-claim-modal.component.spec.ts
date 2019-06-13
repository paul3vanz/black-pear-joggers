import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { EditAwardClaimModalComponent } from './edit-award-claim-modal.component';

describe('EditAwardClaimModalComponent', () => {
  let component: EditAwardClaimModalComponent;
  let fixture: ComponentFixture<EditAwardClaimModalComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ EditAwardClaimModalComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(EditAwardClaimModalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
