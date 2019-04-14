import { Component, Output, EventEmitter, Input } from '@angular/core';

@Component({
  selector: 'bpj-search-bar',
  templateUrl: './search-bar.component.html',
  styleUrls: ['./search-bar.component.scss']
})
export class SearchBarComponent {
  @Input() years: number[];
  @Input() currentYear: number;
  @Input() keywords: string;
  @Output() search = new EventEmitter<string>();
  @Output() setYear = new EventEmitter<number>();

  onSearch(value: string) {
    this.search.emit(value.trim());
  }

  onSetYear(year: number) {
    this.setYear.emit(Number(year));
  }
}
