import { Component, Input, Output, EventEmitter } from '@angular/core';
import { AwardClaim } from 'libs/club-standards-data-access/src/lib/models/award-claim.model';

@Component({
  selector: 'bpj-award-claim-table',
  templateUrl: './award-claim-table.component.html',
  styleUrls: [ './award-claim-table.component.scss' ],
})
export class AwardClaimTableComponent {
  @Input() awards: AwardClaim[];

  @Output() viewRaces = new EventEmitter<AwardClaim>();
  @Output() edit = new EventEmitter<AwardClaim>();
  @Output() archive = new EventEmitter<AwardClaim>();
  @Output() delete = new EventEmitter<AwardClaim>();
  @Output() toggleVerify = new EventEmitter<AwardClaim>();

  filters = {
    archived: null,
  };

  constructor() {}

  onViewRacesClick(awardClaim: AwardClaim) {
    this.viewRaces.emit(awardClaim);
  }

  onEditClick(awardClaim: AwardClaim) {
    this.edit.emit(awardClaim);
  }

  onArchiveClick(awardClaim: AwardClaim) {
    this.archive.emit(awardClaim);
  }

  onDeleteClick(awardClaim: AwardClaim) {
    this.delete.emit(awardClaim);
  }

  onToggleVerifyClick(awardClaim: AwardClaim) {
    this.toggleVerify.emit(awardClaim);
  }

  setFilter(filter: string, value: any) {
    this.filters[filter] = value;
    console.log(filter, value, this.filters);
  }

  awardsWithFilters() {
    return this.awards && this.awards.filter((award) => {
      return Object.entries(this.filters).some(([ filter, value ]) => {
        console.log(filter, value);
        console.log(award);
        return award[filter] == value;
      });
    });
  }
}
