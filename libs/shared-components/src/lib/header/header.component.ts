import { Component } from '@angular/core';
import { Menu } from '../models/menu.model';
import { MenuService } from '../services/menu.service';

@Component({
  selector: 'bpj-header',
  templateUrl: './header.component.html',
  styleUrls: [ './header.component.scss' ],
})
export class HeaderComponent {
  menuOpen = false;
  menuContent: Menu;

  constructor(private menuService: MenuService) {
    this.menuService.fetchMenu().subscribe((menuContent) => {
      this.menuContent = menuContent;
    });
  }

  toggleMenu() {
    this.menuOpen = !this.menuOpen;
  }
}
