import { Page } from './page.types';

export interface Route {
    _id: string;
    path: string;
    page: Page;
    pageRef: string;
}