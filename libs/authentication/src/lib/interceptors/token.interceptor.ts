import { Injectable } from '@angular/core';
import { HttpRequest, HttpHandler, HttpEvent, HttpInterceptor } from '@angular/common/http';
import { Observable } from 'rxjs/Observable';
import { AmplifyService } from 'aws-amplify-angular';

@Injectable()
export class TokenInterceptor implements HttpInterceptor {
  constructor(private amplifyService: AmplifyService) {}
  intercept(request: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    const token = this.amplifyService.auth().user.signInUserSession.idToken.jwtToken;

    request = request.clone({
      setHeaders: {
        Authorization: token ? `Bearer ${token}` : null,
      },
    });

    return next.handle(request);
  }
}
