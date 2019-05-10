import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Menu } from '../models/menu.model';
import { map } from 'rxjs/operators';
import { of } from 'rxjs';

interface StoredMenu {
  expiry: Date;
  menu: Menu;
}

@Injectable({
  providedIn: 'root',
})
export class MenuService {
  constructor(private http: HttpClient) {}

  fetchMenu() {
    const storedMenu = this.getMenuFromStorage();

    if (!storedMenu || (storedMenu && this.hasExpired(storedMenu.expiry))) {
      return this.loadMenu().pipe(
        map((response: Menu) => {
          this.storeMenuInStorage(response);

          return response;
        })
      );
    } else {
      return of(storedMenu.menu);
    }
  }

  private storeMenuInStorage(menuContent: Menu) {
    let expiryTimestamp = new Date();

    expiryTimestamp.setDate(expiryTimestamp.getDate() + 7);

    localStorage.setItem(
      'bpj.menu',
      JSON.stringify({
        expiry: this.getExpiryTimestamp(),
        menu: menuContent,
      })
    );
  }

  private getMenuFromStorage(): StoredMenu {
    try {
      const storedMenu = localStorage.getItem('bpj.menu');
      const parsedMenu = JSON.parse(storedMenu);

      parsedMenu.expiry = new Date(parsedMenu.expiry);

      return parsedMenu;
    } catch (e) {
      return null;
    }
  }

  private loadMenu() {
    return this.http.get('https://bpj.org.uk/wp-json/menus/v1/menus/3');
  }

  private hasExpired(expiryTimestamp: Date): boolean {
    return new Date() > expiryTimestamp;
  }

  private getExpiryTimestamp() {
    let expiryTimestamp = new Date();

    expiryTimestamp.setDate(expiryTimestamp.getDate() + 7);

    return expiryTimestamp;
  }
}
