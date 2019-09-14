import { Component, OnInit, Output, EventEmitter, Input } from '@angular/core';

@Component({
  selector: 'bpj-authentication-bar',
  templateUrl: './authentication-bar.component.html',
  styleUrls: ['./authentication-bar.component.scss']
})
export class AuthenticationBarComponent implements OnInit {
  @Input() user = null;
  @Output() signIn = new EventEmitter<any>();
  @Output() signOut = new EventEmitter<any>();

  constructor() { }

  ngOnInit() {
  }

  onSignIn() {
    this.signIn.emit();
  }

  onSignOut() {
    this.signOut.emit();
  }

}
