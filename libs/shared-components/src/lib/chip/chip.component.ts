import { Component, OnInit, Input, Output, EventEmitter, HostListener, HostBinding } from '@angular/core';

@Component({
  selector: 'bpj-chip',
  templateUrl: './chip.component.html',
  styleUrls: [ './chip.component.scss' ],
})
export class ChipComponent implements OnInit {
  @HostBinding('class.selected')
  @Input()
  selected = false;

  @Output() select = new EventEmitter<boolean>();

  constructor() {}

  ngOnInit() {}

  @HostListener('click', [ '$event' ])
  onSelect(event: Event) {
    event.preventDefault();
    this.selected = !this.selected;
    this.select.emit(this.selected);
  }
}
