import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { InPageNavigationComponent } from './in-page-navigation.component';

describe('InPageNavigationComponent', () => {
  let component: InPageNavigationComponent;
  let fixture: ComponentFixture<InPageNavigationComponent>;

  beforeEach(async(() => {
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
