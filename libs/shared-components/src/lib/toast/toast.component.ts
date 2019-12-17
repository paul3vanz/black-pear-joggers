import { Component } from '@angular/core';

import { ToastService } from '../services/toast.service';
import { Observable } from 'rxjs';

@Component({
  selector: 'bpj-toast',
  templateUrl: './toast.component.html',
  styleUrls: ['./toast.component.scss']
})
export class ToastComponent {
    message$: Observable<string>;

    constructor(private toastService: ToastService) {
        this.message$ = this.toastService.getMessages();
    }
}
