import { ContentItem } from './content.types';

export interface Page {
    _id: string;
    title: string;
    navMenu: any;
    content: ContentItem[];
}