import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { FooterComponent } from './footer/footer.component';
import { HeaderComponent } from './header/header.component';
import { LoaderComponent } from './loader/loader.component';
import { InPageNavigationComponent } from './in-page-navigation/in-page-navigation.component';
import { ModalComponent } from './modal/modal.component';

@NgModule({
  imports: [ CommonModule ],
  declarations: [ HeaderComponent, FooterComponent, LoaderComponent, InPageNavigationComponent, ModalComponent ],
  exports: [ HeaderComponent, FooterComponent, LoaderComponent, InPageNavigationComponent, ModalComponent ],
})
export class SharedComponentsModule {}
