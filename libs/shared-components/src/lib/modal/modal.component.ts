import { Component, Input, HostListener, Output, EventEmitter } from '@angular/core';

@Component({
  selector: 'bpj-modal',
  templateUrl: './modal.component.html',
  styleUrls: [ './modal.component.scss' ],
})
export class ModalComponent {
  @Input() open: boolean;
  @Output() close = new EventEmitter();

  @HostListener('document:keyup.escape', [ '$event' ])
  closeOnEscapeKey(event: KeyboardEvent) {
    this.closeModal();
  }

  closeModal() {
    this.open = false;
    this.close.emit();
  }
}
