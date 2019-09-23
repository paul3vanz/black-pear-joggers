import { Component, EventEmitter, Output, Input } from '@angular/core';
import { MagicMile } from '@black-pear-joggers/magic-mile-data-access';

@Component({
  selector: 'bpj-delete-magic-mile-form',
  templateUrl: './delete-magic-mile-form.component.html',
  styleUrls: ['./delete-magic-mile-form.component.scss']
})
export class DeleteMagicMileFormComponent {
  @Input() results: MagicMile[];

  @Output() delete = new EventEmitter<MagicMile>();

  selectedResultId: string;

  onDeleteClick() {
    this.delete.emit(this.results.find((result) => result.id === Number(this.selectedResultId)));
  }
}
