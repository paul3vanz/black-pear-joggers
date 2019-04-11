import { Action } from '@ngrx/store';

export enum SearchActionTypes {
  Search = '[Search] Search',
}

export class Search implements Action {
  readonly type = SearchActionTypes.Search;
  constructor(public payload: string) {}
}

export type SearchAction = Search;

export const fromSearchActions = {
  Search,
};
