import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { AuthenticationBarComponent } from './authentication-bar.component';

describe('AuthenticationBarComponent', () => {
  let component: AuthenticationBarComponent;
  let fixture: ComponentFixture<AuthenticationBarComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ AuthenticationBarComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(AuthenticationBarComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
