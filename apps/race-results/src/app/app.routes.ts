import { AthletePageComponent } from './containers/athlete-page/athlete-page.component';
import { MeetingPageComponent } from './containers/meeting-page/meeting-page.component';
import { SearchPageComponent } from './containers/search-page/search-page.component';
import { StandardsPageComponent } from './containers/standards-page/standards-page.component';

export const appRoutes = [
  {
    path: '',
    redirectTo: '/results',
    pathMatch: 'full'
  },
  {
    path: 'athlete/:id',
    component: AthletePageComponent
  },
  {
    path: 'meeting/:date/:id',
    component: MeetingPageComponent
  },
  {
    path: 'results',
    component: SearchPageComponent
  },
  {
    path: 'standards',
    component: StandardsPageComponent
  }
];
