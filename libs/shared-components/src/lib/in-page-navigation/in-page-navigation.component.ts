import { Component, HostListener } from '@angular/core';

@Component({
  selector: 'bpj-in-page-navigation',
  templateUrl: './in-page-navigation.component.html',
  styleUrls: ['./in-page-navigation.component.scss']
})
export class InPageNavigationComponent {
  @HostListener('click', ['$event'])
  onLinkClick(event: Event) {
    const target = <HTMLLinkElement>event.target;

    if (target.href && target.href.includes('#')) {
      const destinationElement = document.getElementById(
        target.href.split('#')[1]
      );
      event.preventDefault();
      destinationElement.scrollIntoView({ behavior: 'smooth' });
    }
  }
}
