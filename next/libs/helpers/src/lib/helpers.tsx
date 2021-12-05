import {
  formatRelative,
  parseISO,
  format,
  isToday,
  isTomorrow,
} from 'date-fns';

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

export function classNames(...classNames: string[]): string {
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

export function friendlyTime(time: string) {
  const timeAsMoment = moment(time, 'HH:mm');

  return timeAsMoment.minutes()
    ? timeAsMoment.format('h:mma')
    : timeAsMoment.format('ha');
}

export function friendlyDate(dateString: string) {
  if (!dateString) return dateString;

  const date = parseISO(dateString.substr(0, 10));

  if (isToday(date)) {
    return 'Today';
  } else if (isTomorrow(date)) {
    return 'Tomorrow';
  } else {
    return formatRelative(date, new Date(), { weekStartsOn: 1 });
  }
}
