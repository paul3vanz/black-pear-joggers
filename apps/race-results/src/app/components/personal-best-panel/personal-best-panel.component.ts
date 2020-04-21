import { Component, Input, OnChanges } from '@angular/core';
import { Chart } from 'chart.js';
import { Paging } from '../../models/paging';
import { Result } from '../../models/result';
import * as moment from 'moment-mini-ts';
import { PacePipe } from 'libs/shared-pipes/src/lib/pipes/pace.pipe';

@Component({
  selector: 'bpj-personal-best-panel',
  templateUrl: './personal-best-panel.component.html',
  styleUrls: ['./personal-best-panel.component.scss']
})
export class PersonalBestPanelComponent implements OnChanges {
  @Input() eventName = '5K';
  @Input() loading: boolean;
  @Input() personalBests: any;
  @Input() results: Paging<Result>;
  chart = [];

  constructor(private pacePipe: PacePipe) {}

  ngOnChanges() {
    if (!this.results || !this.results.data) {
      return;
    }

    const chartDataMile = [];
    const chartData5K = [];
    const chartData10K = [];
    const chartDataHM = [];
    const chartDataMar = [];

    // const chartData = {
    //   mile: { label: 'Mile', data: [], includedEvents: [ '1M', 'Mile' ], borderColor: '#fff', fill: false },
    //   five: { label: '5K', data: [], includedEvents: [ '5K', 'parkrun' ], borderColor: '#fff', fill: false },
    //   ten: { label: '10K', data: [], includedEvents: [ '10K', '10KMT' ], borderColor: '#fff', fill: false },
    //   half: { label: 'Half Marathon', data: [], includedEvents: [ 'HM', 'HMMT' ], borderColor: '#fff', fill: false },
    //   marathon: { label: 'Marathon', data: [], includedEvents: [ 'Mar', 'MarMT' ], borderColor: '#fff', fill: false },
    // };

    this.get5K().forEach(result => {
      chartData5K.push({
        x: new Date(result.date),
        y: this.pacePipe.transform(result.time_parsed, '5K', true),
        time: result.time_parsed,
        event: result.race
      });
    });

    this.get10K().forEach(result => {
      chartData10K.push({
        x: new Date(result.date),
        y: this.pacePipe.transform(result.time_parsed, '10K', true),
        time: result.time_parsed,
        event: result.race
      });
    });

    this.getHM().forEach(result => {
      chartDataHM.push({
        x: new Date(result.date),
        y: this.pacePipe.transform(result.time_parsed, 'Half Marathon', true),
        time: result.time_parsed,
        event: result.race
      });
    });

    this.getMar().forEach(result => {
      chartDataMar.push({
        x: new Date(result.date),
        y: this.pacePipe.transform(result.time_parsed, 'Marathon', true),
        time: result.time_parsed,
        event: result.race
      });
    });

    this.chart = new Chart('canvas', {
      type: 'line',
      data: {
        datasets: [
          {
            data: chartData5K,
            label: '5K',
            borderColor: '#f89829',
            fill: false
          },
          {
            data: chartData10K,
            label: '10K',
            borderColor: '#ccc',
            fill: false
          },
          {
            data: chartDataHM,
            label: 'Half Marathon',
            borderColor: '#999',
            fill: false
          },
          {
            data: chartDataMar,
            label: 'Marathon',
            borderColor: '#000',
            fill: false
          }
        ]
      },
      options: {
        maintainAspectRatio: false,
        legend: {
          position: false
        },
        tooltips: {
          mode: 'nearest',
          intersect: false,
          callbacks: {
            title: (tooltipItem, data) => {
              return data.datasets[tooltipItem[0].datasetIndex].data[
                tooltipItem[0].index
              ].event;
              // console.log(tooltipItem);
            },
            label: (tooltipItem, data) => {
              const dataItem =
                data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index];
              const finishTime = dataItem.time;
              const event = data.datasets[tooltipItem.datasetIndex].label;
              const formattedTime = this.formattedTime(finishTime);
              const pace = this.pacePipe.transform(finishTime, event);

              return `${formattedTime} (${pace})`;
            }
          }
        },
        scales: {
          xAxes: [
            {
              type: 'time',
              time: {
                unit: 'month'
              }
            }
          ],
          yAxes: [
            {
              ticks: {
                callback: (value, index, values) => {
                  // return this.formattedTime(value);
                }
              }
            }
          ]
        },
        title: {
          display: false,
          text: 'Race history'
        }
      }
    });
  }

  formattedTime(timeInSeconds: number) {
    return new Date(timeInSeconds * 1000)
      .toISOString()
      .substr(11, 8)
      .toString()
      .substring(timeInSeconds >= 3600 ? 1 : 3);
  }

  get5K() {
    return this.results.data.filter(result => {
      return ['5K', 'parkrun'].includes(result.event) && result.isPersonalBest;
    });
  }

  get10K() {
    return this.results.data.filter(result => {
      return ['10K', '10KMT'].includes(result.event) && result.isPersonalBest;
    });
  }

  getHM() {
    return this.results.data.filter(result => {
      return ['HM', 'HMMT'].includes(result.event) && result.isPersonalBest;
    });
  }

  getMar() {
    return this.results.data.filter(result => {
      return ['Mar', 'MarMT'].includes(result.event) && result.isPersonalBest;
    });
  }
}
