import { Component, OnInit } from '@angular/core';
import { Store } from '@ngrx/store';
import { SubmitMagicMile } from '../../+state/magic-mile.actions';

@Component({
  selector: 'bpj-magic-mile-page',
  templateUrl: './magic-mile-page.component.html',
  styleUrls: ['./magic-mile-page.component.scss']
})
export class MagicMilePageComponent implements OnInit {

  constructor(private store$: Store<any>) { }

  ngOnInit() {
  }

  onSubmit(form: any) {
    this.store$.dispatch(new SubmitMagicMile(form));
  }

}
