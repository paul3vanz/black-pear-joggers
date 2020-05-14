import { Injectable } from '@angular/core';
import { ActivatedRouteSnapshot, RouterStateSnapshot, UrlTree, CanActivate, Router, CanActivateChild } from '@angular/router';
import { Observable, of } from 'rxjs';
import { map, tap } from 'rxjs/operators';
import { AuthService } from '../services/auth.service';

@Injectable({
  providedIn: 'root',
})
export class AuthenticatedGuard implements CanActivate {
  canActivate(): boolean {
    return true;
    // if (this.amplifyService.auth().user) {
    //   return true;
    // } else {
    //   this.router.navigate(['/auth']);

    //   return false;
    // }
  }

  constructor(private authService: AuthService, private router: Router) {}
}
