import { Component, AfterContentInit, Input, HostBinding, Output, EventEmitter, QueryList, ContentChildren } from '@angular/core';
import { FormGroup } from '@angular/forms';

@Component({
  selector: 'bpj-step',
  templateUrl: './step.component.html',
  styleUrls: [ './step.component.scss' ],
})
export class StepComponent {
  @Input()
  @HostBinding('class.active')
  active = false;
  @Input() nextLabel = 'Next';
  @Input() showBack = true;
  @Input() title: string;
  @Input() form: FormGroup;

  @Output() back = new EventEmitter();
  @Output() next = new EventEmitter();

  onBackButton() {
    this.back.emit();
  }

  onNextButton() {
    this.next.emit(this.form.valid);
  }
}
