import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MagicMilePageComponent } from './containers/magic-mile-page/magic-mile-page.component';
import { RouterModule } from '@angular/router';
import { RecordMagicMileFormComponent } from './components/record-magic-mile-form/record-magic-mile-form.component';
import { ReactiveFormsModule } from '@angular/forms';

@NgModule({
  declarations: [MagicMilePageComponent, RecordMagicMileFormComponent],
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterModule.forChild([
      {
        path: '',
        component: MagicMilePageComponent,
      }
    ]),
  ]
})
export class MagicMileModule { }
