import { Component, EventEmitter, Input, Output } from '@angular/core';

@Component({
  selector: 'bpj-search-bar',
  templateUrl: './search-bar.component.html',
  styleUrls: [ './search-bar.component.scss' ],
})
export class SearchBarComponent {
  @Input() keywords = '';
  @Input() loading: boolean;
  @Output() search = new EventEmitter<string>();
}
