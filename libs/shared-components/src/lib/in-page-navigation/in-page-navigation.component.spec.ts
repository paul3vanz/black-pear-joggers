import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';

import { InPageNavigationComponent } from './in-page-navigation.component';

describe('InPageNavigationComponent', () => {
  let component: InPageNavigationComponent;
  let fixture: ComponentFixture<InPageNavigationComponent>;

  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
      declarations: [InPageNavigationComponent]
    }).compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(InPageNavigationComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
