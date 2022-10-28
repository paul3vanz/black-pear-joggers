import { Page } from './page.types';
import { Slug } from './slug.types';

export interface Route {
    _id: string;
    page: Page;
    slug: Slug;
}