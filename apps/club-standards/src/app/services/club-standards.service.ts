import * as moment from 'moment-mini-ts';
import { AwardClaim } from '../models/award-claim.model';
import { AwardClaimRace } from '../models/award-claim-race.model';
import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { Standard } from '../models/standard.model';


@Injectable({
    providedIn: 'root',
})
export class ClubStandardsService {
    apiRootUrl = 'https://bpj.org.uk/api/public/index.php';
    standardsUrl = '/standards';

    constructor(private http: HttpClient) { }

    getStandards(gender: string, category: string): Observable<Standard[]> {
        return this.http.get<Standard[]>(`${this.apiRootUrl}/standards/${gender}/${category}`);
    }

    getAwardClaim(id: number, uniqueToken: string): Observable<AwardClaim> {
        return this.http.get<AwardClaim>(`${this.apiRootUrl}/awardclaim/${id}/${uniqueToken}`);
    }

    submitClaim(claimDetails: AwardClaim) {
        console.log('submitClaim', claimDetails);
        return this.http.post(`${this.apiRootUrl}/awardclaim`, claimDetails);
    }

    timeToSeconds(hours: number | string, minutes: number | string, seconds: number | string) {
        return Number(hours) * 3600 + Number(minutes) * 60 + Number(seconds);
    }

    timeFormatted(hours: number | string, minutes: number | string, seconds: number | string) {
        return Number(hours)
            ? `${hours}:${this.addLeadingZero(minutes)}:${this.addLeadingZero(seconds)}`
            : `${minutes}:${this.addLeadingZero(seconds)}`;
    }

    addLeadingZero(number: number | string) {
        return String(number).padStart(2, '0');
    }

    convertFormModelToApiModel(formModel: any): AwardClaim {
        console.log('convert', formModel);

        return {
            gender: formModel.categoryDetails.gender,
            category: formModel.categoryDetails.category,
            award: formModel.categoryDetails.certificate,
            firstName: formModel.personalDetails.firstName,
            lastName: formModel.personalDetails.lastName,
            email: formModel.personalDetails.email,
            races: formModel.races.map((race) => {
                return {
                    ...race,
                    date: moment(race.date, 'DD/MM/YYYY').format('YYYY-MM-DD'),
                    time: this.timeFormatted(race.finishTime.hours, race.finishTime.minutes, race.finishTime.seconds),
                    timeParsed: this.timeToSeconds(race.finishTime.hours, race.finishTime.minutes, race.finishTime.seconds),
                };
            }),
        };
    }

    displayCertificate() {
        var win = window.open(
            '',
            'Title',
            'toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,width=780,height=200,top=' +
            (screen.height - 400) +
            ',left=' +
            (screen.width - 840)
        );
        win.document.body.innerHTML = 'HTML';
    }
}
