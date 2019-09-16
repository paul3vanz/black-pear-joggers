import { Component, OnInit, Input, HostBinding } from '@angular/core';

@Component({
  selector: 'bpj-loader',
  templateUrl: './loader.component.html',
  styleUrls: ['./loader.component.scss']
})
export class LoaderComponent implements OnInit {
  @Input() @HostBinding('class.dark') dark = false;

  constructor() {}

  ngOnInit() {}
}
