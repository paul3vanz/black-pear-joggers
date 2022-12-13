import { ContentItem, Illustration, Image } from './content.types';
import { PortableTextBlock } from '@portabletext/types';
import { Slug } from './slug.types';

export interface ClubRun {
    _type: 'clubRun';
    _id: string;
    disabled: boolean;
    title: string;
    day: 'Monday' | 'Tuesday' | 'Wednesday' | 'Thursday' | 'Friday' | 'Saturday' | 'Sunday';
    image: Image;
    slug: Slug;
    summary: PortableTextBlock[];
    content: ContentItem[];
    time: string;
    venue: any;
}