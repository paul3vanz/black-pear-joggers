import { Component, Input, Output, EventEmitter, HostListener, HostBinding } from '@angular/core';

@Component({
  selector: 'bpj-chip',
  templateUrl: './chip.component.html',
  styleUrls: [ './chip.component.scss' ],
})
export class ChipComponent {
  @HostBinding('class.selected')
  @Input()
  selected = false;
  @Input() value: string;

  @Output() select = new EventEmitter<string>();

  @HostListener('click', [ '$event' ])
  onSelect(event: Event) {
    event.preventDefault();
    this.select.emit(this.value);
  }
}
