import { Component, Input, Output, EventEmitter, ViewChild, ElementRef } from '@angular/core';
import { Subject } from 'rxjs';
import { distinctUntilChanged, debounceTime, skip } from 'rxjs/operators';

@Component({
  selector: 'bpj-inline-edit-field',
  templateUrl: './inline-edit-field.component.html',
  styleUrls: [ './inline-edit-field.component.scss' ],
})
export class InlineEditFieldComponent {
  @Input() label: string;
  @Output() update = new EventEmitter<string>();

  value$ = new Subject<string>();
  editMode = false;

  @ViewChild('inputField', { static: false }) input: ElementRef;

  constructor() {
    this.value$.pipe(
      distinctUntilChanged(),
      skip(1),
      debounceTime(500),
    ).subscribe((value) => {
      this.update.emit(value);
    });
  }

  onUpdate(value: string) {
    this.label = value;
    this.value$.next(value);
  }

  edit() {
    this.editMode = true;

    // Ensures event is fired
    setTimeout(() => {
      this.input.nativeElement.focus();
      this.input.nativeElement.select();
    }, 0);
  }

  save() {
    this.editMode = false;
  }
}
