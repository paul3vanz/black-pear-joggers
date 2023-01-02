import {
    Component,
    EventEmitter,
    Input,
    Output
    } from '@angular/core';
import { LoadingState, Result } from '@black-pear-joggers/race-results-data-access';
import { Paging } from '../../models/paging';


@Component({
    selector: 'bpj-athlete-results',
    templateUrl: './athlete-results.component.html',
    styleUrls: ['./athlete-results.component.scss'],
})
export class AthleteResultsComponent {
    @Input() loadingState: LoadingState;
    @Input() year: string;
    @Input() results: Paging<Result>;
    @Output() previous = new EventEmitter();
    @Output() next = new EventEmitter();

    filter: string;
    latestYear: number;
    firstYear: number;
    years: number[] = [];
}
