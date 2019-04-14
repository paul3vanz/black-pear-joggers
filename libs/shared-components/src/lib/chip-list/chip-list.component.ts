import { Component, OnInit, Output, EventEmitter, Input } from '@angular/core';

@Component({
  selector: 'bpj-chip-list',
  templateUrl: './chip-list.component.html',
  styleUrls: [ './chip-list.component.scss' ],
})
export class ChipListComponent implements OnInit {
  @Input() allowMultipleSelected = false;
  @Output() select = new EventEmitter<boolean>();

  constructor() {}

  ngOnInit() {}

  onSelect() {
    this.select.emit();
    console.log('list emit');
  }
}
