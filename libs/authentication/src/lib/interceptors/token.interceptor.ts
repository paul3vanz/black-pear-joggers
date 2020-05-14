import { Injectable } from '@angular/core';
import { HttpRequest, HttpHandler, HttpEvent, HttpInterceptor } from '@angular/common/http';
import { Observable } from 'rxjs';
// import { AmplifyService } from 'aws-amplify-angular';

@Injectable()
export class TokenInterceptor implements HttpInterceptor {
  constructor() {}
  intercept(request: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    // const user = this.amplifyService.auth().user;
    // const token = user ? user.signInUserSession.idToken.jwtToken : null;

    // if (token) {
    //   request = request.clone({
    //     setHeaders: {
    //       Authorization: `Bearer ${token}`
    //     }
    //   });
    // }

    return next.handle(request);
  }
}
