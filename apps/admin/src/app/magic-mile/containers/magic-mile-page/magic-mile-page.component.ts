import { Component, OnInit } from '@angular/core';
import { Observable } from 'rxjs';
import { Store } from '@ngrx/store';

import { loadResults, createResult, deleteResult, MagicMile } from '@black-pear-joggers/magic-mile-data-access';

@Component({
  selector: 'bpj-magic-mile-page',
  templateUrl: './magic-mile-page.component.html',
  styleUrls: ['./magic-mile-page.component.scss']
})
export class MagicMilePageComponent implements OnInit {
  results$: Observable<MagicMile[]>;

  constructor(private store$: Store<any>) {
    this.results$ = this.store$.select((store) => store.magicMile.list);
  }

  ngOnInit() {
    this.store$.dispatch(loadResults());
  }

  onSubmit(form: any) {
    this.store$.dispatch(createResult());
  }

  onDeleteClick(result: MagicMile) {
    this.store$.dispatch(deleteResult({ result: result }));
  }

}
