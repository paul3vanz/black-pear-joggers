import { Component } from '@angular/core';
import { Store } from '@ngrx/store';
import { fromClubStandardsActions } from './+state/club-standards.actions';

@Component({
  selector: 'bpj-root',
  templateUrl: './app.component.html',
  styleUrls: [ './app.component.scss' ],
})
export class AppComponent {
  title = 'Club standards | BPJ';

  onClaimAwardClick() {
    location.href = 'https://docs.google.com/forms/d/e/1FAIpQLSdVYbxf7DYjH0QSWBDmpyV3yyC0RWh9jzrQ-1hoPcyCTGCvzA/viewform';
    // this.store$.dispatch(new fromClubStandardsActions.ClubStandardsClaimStart());
  }

  constructor(private store$: Store<any>) {}
}
