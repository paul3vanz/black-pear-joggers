import { Component, OnInit, Input } from '@angular/core';

@Component({
  selector: 'bpj-icon',
  templateUrl: './icon.component.html',
  styleUrls: ['./icon.component.scss']
})
export class IconComponent implements OnInit {
  @Input() icon: string;
  @Input() colour: string;

  constructor() { }

  ngOnInit() {
  }

}
