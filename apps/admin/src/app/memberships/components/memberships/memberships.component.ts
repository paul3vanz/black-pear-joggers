import { AfterViewInit, ChangeDetectionStrategy, Component, Input, OnChanges, ViewChild } from '@angular/core';

import { Athlete } from '@black-pear-joggers/race-results-data-access';
import { MatSort } from '@angular/material/sort';
import { MatTableDataSource } from '@angular/material/table';
import { Membership } from 'libs/membership-data-access/src/lib/models/membership.model';

@Component({
  selector: 'bpj-memberships',
  templateUrl: './memberships.component.html',
  styleUrls: ['./memberships.component.scss'],
})
export class MembershipsComponent implements OnChanges, AfterViewInit {
  @Input() loading: boolean;
  @Input() athletes: Athlete[];
  @Input() memberships: Membership[];

  @ViewChild(MatSort) sort: MatSort;

  dataSource: MatTableDataSource<Membership> = new MatTableDataSource();

  search: string;

  displayedColumns = ['Urn', 'Lastname', 'Gender', 'Dob', 'CompetitiveRegStatus', 'athlete'];

  constructor() {}

  ngOnChanges(): void {
    this.dataSource.data = this.memberships;
  }

  ngAfterViewInit(): void {
    this.dataSource.sort = this.sort;
  }

  applyFilter(filterValue: string): void {
    this.dataSource.filter = filterValue.trim().toLowerCase();
  }

  findAthleteByUrn(urn: string) {
    console.log(urn)
    return this.athletes?.some((athlete) => athlete.last_name === urn)
  }
}
