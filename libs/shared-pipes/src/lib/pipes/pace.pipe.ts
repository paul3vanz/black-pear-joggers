import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'pace'
})
export class PacePipe implements PipeTransform {
  transform(
    timeInSeconds: number,
    distanceInMetersOrEventName: number | string,
    returnAsNumber?: boolean
  ): string | number {
    const distanceInMeters =
      typeof distanceInMetersOrEventName === 'string'
        ? this.getDistanceByEventName(distanceInMetersOrEventName)
        : distanceInMetersOrEventName;

    const metersPerSecond = distanceInMeters / timeInSeconds;
    const minutesPerMile = 26.8224 / metersPerSecond;
    const minutes = Math.floor(minutesPerMile);
    const seconds = Math.floor((minutesPerMile - minutes) * 60);

    const secondsFormatted =
      seconds < 10 ? seconds.toString().padStart(2, '0') : seconds;

    return returnAsNumber
      ? minutesPerMile
      : `${minutes}:${secondsFormatted}/mile`;
  }

  private getDistanceByEventName(eventName: string): number {
    switch (eventName) {
      case 'Mile':
        return 1609.34;
      case '5K':
        return 5000;
      case '10K':
        return 10000;
      case 'Half Marathon':
        return 21097.5;
      case 'Marathon':
        return 42195;
      default:
        throw `${eventName} not valid event`;
    }
  }
}
