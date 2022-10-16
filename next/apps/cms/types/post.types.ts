import { PortableTextBlock } from '@portabletext/types';
import { Slug } from './slug.types';

export interface Post {
    _id: string;
    title: string;
    slug: Slug;
    body: PortableTextBlock[];
    publishedAt: string;
    imageUrl: string;
    authors: any;
}


