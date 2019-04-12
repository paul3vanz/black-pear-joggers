import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'pace',
})
export class PacePipe implements PipeTransform {
  transform(timeInSeconds: number, distanceInMeters: number): string {
    const metersPerSecond = distanceInMeters / timeInSeconds;
    const minutesPerMile = 26.8224 / metersPerSecond;
    const minutes = Math.floor(minutesPerMile);
    const seconds = Math.floor((minutesPerMile - minutes) * 60);

    const secondsFormatted = seconds < 10 ? seconds.toString().padStart(2, '0') : seconds;

    return `${minutes}:${secondsFormatted}/mile`;
  }
}
