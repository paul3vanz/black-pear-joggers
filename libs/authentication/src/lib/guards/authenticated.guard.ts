import { Injectable } from '@angular/core';
import { ActivatedRouteSnapshot, RouterStateSnapshot, UrlTree, CanActivate, Router, CanActivateChild } from '@angular/router';
import { Observable, of } from 'rxjs';
import { AmplifyService } from 'aws-amplify-angular';
import { map, tap } from 'rxjs/operators';

@Injectable({
  providedIn: 'root'
})
export class AuthenticatedGuard implements CanActivate {
  canActivate(): boolean {
    if (this.amplifyService.auth().user) {
      return true;
    } else {
      this.router.navigate(['/auth']);

      return false;
    }
  }

  constructor(
    private amplifyService: AmplifyService,
    private router: Router
  ) {}
}
