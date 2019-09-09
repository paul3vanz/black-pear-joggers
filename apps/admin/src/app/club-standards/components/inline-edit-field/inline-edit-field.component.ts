import { Component, OnInit, Input, Output, EventEmitter, ViewChild, ElementRef } from '@angular/core';

@Component({
  selector: 'bpj-inline-edit-field',
  templateUrl: './inline-edit-field.component.html',
  styleUrls: [ './inline-edit-field.component.scss' ],
})
export class InlineEditFieldComponent implements OnInit {
  @Input() label: string;
  @Output() update = new EventEmitter<string>();

  editMode = false;

  @ViewChild('inputField', { static: false }) input: ElementRef;

  constructor() {}

  ngOnInit() {
    // console.log(this.input);
  }

  onUpdate(value: string) {
    this.update.emit(value);
  }

  edit() {
    this.editMode = true;
    console.log(this.input.nativeElement);

    setTimeout(() => {
      this.input.nativeElement.focus();
      this.input.nativeElement.select();
    }, 0);
  }

  save() {
    this.editMode = false;
  }
}
