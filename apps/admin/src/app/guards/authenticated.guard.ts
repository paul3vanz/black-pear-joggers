import { Injectable } from '@angular/core';
import { ActivatedRouteSnapshot, RouterStateSnapshot, UrlTree, CanActivate, Router, CanActivateChild } from '@angular/router';
import { Observable, of } from 'rxjs';
import { AmplifyService } from 'aws-amplify-angular';
import { map, take, switchMap, tap } from 'rxjs/operators';

@Injectable({
  providedIn: 'root'
})
export class AuthenticatedGuard implements CanActivate, CanActivateChild {
  canActivate(
    route: ActivatedRouteSnapshot,
    state: RouterStateSnapshot
  ): Observable<boolean> {
    console.log('authGuard');
    return this.amplifyService.authStateChange$
      .pipe(
        tap((authState) => {
          console.log('tap', authState);
        }),
        map((authState) => {
          console.log('authState', authState);

          if (authState.user) {
            console.log('isAuthed');
            return true;
          } else {
            console.log('redirectToAuth');
            this.router.navigate(['/auth']);
            return false;
          }
        })
      );
  }

  canActivateChild(
    route: ActivatedRouteSnapshot,
    state: RouterStateSnapshot): boolean {
    return this.canActivate(route, state);
  }

  constructor(
    private amplifyService: AmplifyService,
    private router: Router
  ) {}
}
