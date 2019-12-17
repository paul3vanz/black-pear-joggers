import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { delay } from 'rxjs/operators';

@Injectable({
    providedIn: 'root',
})
export class ToastService {
    messages$ = new BehaviorSubject<string>(null);

    constructor() {}

    pushMessage(message: string) {
        console.log(message);
        this.messages$.next(message);

        setTimeout(() => {
            this.messages$.next(null);
        }, 2000);
    }

    getMessages() {
        return this.messages$;
    }
}
