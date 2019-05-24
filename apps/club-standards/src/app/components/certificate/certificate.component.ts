import { Component, OnInit, Input } from '@angular/core';
import { AwardClaim } from '../../models/award-claim.model';

@Component({
  selector: 'bpj-certificate',
  templateUrl: './certificate.component.html',
  styleUrls: [ './certificate.component.scss' ],
})
export class CertificateComponent implements OnInit {
  @Input() certificate: AwardClaim;

  constructor() {}

  ngOnInit() {}
}
