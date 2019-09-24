import { Component, OnInit } from '@angular/core';
import { Observable, Subject } from 'rxjs';
import { loadResults, magicMileQuery, MagicMile } from '@black-pear-joggers/magic-mile-data-access';
import { Store } from '@ngrx/store';
import { ActivatedRoute, Router } from '@angular/router';
import { filter, take } from 'rxjs/operators';
import { LoadingState } from 'libs/authentication/src/lib/models/loading-state.model';

@Component({
  selector: 'bpj-magic-mile-page',
  templateUrl: './magic-mile-page.component.html',
  styleUrls: [ './magic-mile-page.component.scss' ],
})
export class MagicMilePageComponent implements OnInit {
  error$: Observable<any>;
  keywords: string;
  loaded$: Observable<LoadingState>;
  results$: Observable<MagicMile[]>;

  displayFormats = [
    { label: 'Recent First', value: 'recent' },
    { label: 'Fastest First', value: 'fastest' },
  ];
  displayFormat = 'recent';

  constructor(private store$: Store<any>, private route: ActivatedRoute, private router: Router) {
    this.loaded$ = this.store$.select(magicMileQuery.getCallState);
    this.error$ = this.store$.select(magicMileQuery.getError);
    this.results$ = this.store$.select(magicMileQuery.getMagicMileSearch(this.keywords));
  }

  ngOnInit() {
    this.store$.dispatch(loadResults());

    this.route.queryParams.pipe(take(1), filter((params) => params.sort)).subscribe((params) => {
      this.displayFormat = params.sort;
    });

    this.route.queryParams.pipe(take(1), filter((params) => params.search)).subscribe((params) => {
      this.onSearch(params.search);
    });
  }

  onSearch(keywords: string) {
    this.keywords = keywords;

    this.results$ = this.store$.select(magicMileQuery.getMagicMileSearch(this.keywords));

    this.updateQueryParameter('search', keywords);
  }

  onSelectDisplayFormat(format: string) {
    this.displayFormat = format;
    this.updateQueryParameter('sort', this.displayFormat);
  }

  updateQueryParameter(key: string, value: string) {
    this.router.navigate([ '.' ], {
      relativeTo: this.route,
      queryParams: {
        [key]: value || null,
      },
      queryParamsHandling: 'merge',
    });
  }
}
