import { Result } from './result.model';

export interface EventWithResult {
  name: string;
  distance: number;
  aliases: string[];
  best: Result;
}

export const includedEvents: EventWithResult[] = [
  { name: 'Mile', distance: 1609.34, aliases: ['Mile', '1M'], best: null },
  { name: '5K', distance: 5000, aliases: ['5K', 'parkrun'], best: null },
  { name: '10K', distance: 10000, aliases: ['10K', '10KMT'], best: null },
  { name: 'HM', distance: 21097.5, aliases: ['HM', 'HMMT'], best: null },
  { name: 'Mar', distance: 42195, aliases: ['Mar', 'MarMT'], best: null }
];
