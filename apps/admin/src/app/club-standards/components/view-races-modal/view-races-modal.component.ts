import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import { AwardClaim } from 'libs/club-standards-data-access/src/lib/models/award-claim.model';
import { AwardClaimRace } from 'libs/club-standards-data-access/src/lib/models/award-claim-race.model';

@Component({
  selector: 'bpj-view-races-modal',
  templateUrl: './view-races-modal.component.html',
  styleUrls: ['./view-races-modal.component.scss']
})
export class ViewRacesModalComponent implements OnInit {
  @Input() awardClaim: AwardClaim;
  @Output() update = new EventEmitter<AwardClaimRace>();

  constructor() { }

  ngOnInit() {
  }

  onUpdate(awardClaimRaceId: number, raceName: string) {
    this.update.emit({
      ...this.awardClaim.races.find((race) => race.id === awardClaimRaceId),
      race: raceName,
    });
  }

}
