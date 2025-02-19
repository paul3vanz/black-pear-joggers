import { Component, OnInit } from '@angular/core';
import { Store } from '@ngrx/store';
import { fromClubStandardsActions } from './+state/club-standards.actions';
import { AwardClaim } from './models/award-claim.model';
import { ClubStandardsService } from './services/club-standards.service';

@Component({
    selector: 'bpj-root',
    templateUrl: './app.component.html',
    styleUrls: ['./app.component.scss'],
})
export class AppComponent implements OnInit {
    showCertificate = false;
    certificate: AwardClaim;
    title = 'Club standards | BPJ';

    onClaimAwardClick() {
        location.href = 'https://bpj.org.uk/claim-award';
    }

    constructor(private store$: Store<any>, private clubStandardsService: ClubStandardsService) { }

    ngOnInit() {
        const searchParams = new URLSearchParams(location.search);

        if (searchParams.get('certificateId')) {
            const certificateId = searchParams.get('certificateId');
            const uniqueToken = searchParams.get('token');

            this.clubStandardsService.getAwardClaim(Number(certificateId), uniqueToken).subscribe((certificate) => {
                this.certificate = certificate;
                this.showCertificate = true;
            });
        }
    }
}
