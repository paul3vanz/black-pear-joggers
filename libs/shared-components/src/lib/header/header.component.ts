import { Component, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Menu } from '../models/menu.model';

@Component({
  selector: 'bpj-header',
  templateUrl: './header.component.html',
  styleUrls: [ './header.component.scss' ],
})
export class HeaderComponent implements OnInit {
  menuOpen = false;
  menuContent: Menu;

  constructor(private http: HttpClient) {}

  ngOnInit() {
    this.http.get('https://bpj.org.uk/wp-json/menus/v1/menus/3').subscribe((response: Menu) => {
      this.menuContent = response;
    });
  }

  toggleMenu() {
    this.menuOpen = !this.menuOpen;
  }
}
