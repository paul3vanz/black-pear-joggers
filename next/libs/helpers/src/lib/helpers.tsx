import {
    format,
    isBefore,
    isToday,
    isTomorrow,
    parseISO
    } from 'date-fns';
import { MutableRefObject, useRef } from 'react';
import { PortableTextBlock } from '@portabletext/types';

function moment(...test: any[]): any {
  return null;
}

export function blogPostUrl(blogPost: any): string {
  const publishDate = moment(blogPost.fields.publishDate);

  return [
    '/news',
    publishDate.format('YYYY'),
    publishDate.format('MM'),
    publishDate.format('DD'),
    blogPost.fields.slug,
  ].join('/');
}

export function classNames(...classNames: (string | undefined)[]): string {
  return classNames.filter(Boolean).join(' ');
}

export function fileSize(bytes: number, decimals = 2): string {
  if (bytes === 0) return '0 Bytes';

  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];

  const i = Math.floor(Math.log(bytes) / Math.log(k));

  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

export function mapClassNames(
  value: string | undefined,
  map: { [key: string]: string }
) {
  return value ? map[value] || map.default || '' : map.default || '';
}

export function hasTag(tags: string[], tag: string): boolean {
  return tags?.some((currentTag) => currentTag === tag);
}

export function friendlyDate(dateString: string) {
  if (!dateString) return dateString;

  const date = parseISO(dateString.substring(0, 10));

  if (isToday(date)) {
    return 'Today';
  } else if (isTomorrow(date)) {
    return 'Tomorrow';
  } else {
    return format(date, 'd-MMM-yy');
  }
}

export function shortDate(date?: string) {
  return format(date ? parseISO(date) : new Date(), 'yyyy-MM-dd');
}

export function dateIsBefore(date: string, dateToCompare: string): boolean {
  return isBefore(parseISO(date), parseISO(dateToCompare));
}

export function timeFormatted(timeInSeconds: number): string {
  if (!timeInSeconds) return '';

  return `${Math.floor(timeInSeconds / 60)}:${String(
    timeInSeconds % 60
  ).padStart(2, '0')}`;
}

export function formatGender(gender: string): string {
  return gender === 'M' ? 'Male' : gender === 'F' ? 'Female' : '';
}

export function scrollIntoView(element: Element): void {
  setTimeout(
    () =>
      element.scrollIntoView({
        behavior: 'smooth',
      }),
    0
  );
}

export function stepNamesToRefs(stepNames: string[]): {
  [key: string]: MutableRefObject<HTMLDivElement>;
} {
  return stepNames.reduce(
    (a, v) => ({ ...a, [v]: useRef<HTMLDivElement>() }),
    {}
  );
}

export function toPlainText(blocks: PortableTextBlock[]) {
  return blocks
    .map((block) => {
      if (block._type !== 'block' || !block.children) {
        return '';
      }

      return block.children.map((child) => child.text).join('');
    })
    .join('\n\n');
}
