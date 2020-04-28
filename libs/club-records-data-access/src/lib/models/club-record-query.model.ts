import { ClubRecord } from './club-record.model';

export interface ClubRecordQuery {
  record: ClubRecord;
  reason: string;
  notes: string;
}
