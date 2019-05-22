import { Component, Input, OnChanges } from '@angular/core';
import { Chart } from 'chart.js';
import { Paging } from '../../models/paging';
import { Result } from '../../models/result';
import * as moment from 'moment-mini-ts';

@Component({
  selector: 'bpj-personal-best-panel',
  templateUrl: './personal-best-panel.component.html',
  styleUrls: [ './personal-best-panel.component.scss' ],
})
export class PersonalBestPanelComponent implements OnChanges {
  @Input() results: Paging<Result>;
  chart = [];

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

    this.results.data
      .filter((result) => {
        return [ '5K', 'parkrun' ].includes(result.event);
      })
      .forEach((result) => {
        chartData5K.push({ x: new Date(result.date), y: result.time_parsed });
      });

    this.results.data
      .filter((result) => {
        return [ '10K', '10KMT' ].includes(result.event);
      })
      .forEach((result) => {
        chartData10K.push({ x: new Date(result.date), y: result.time_parsed });
      });

    this.results.data
      .filter((result) => {
        return [ 'HM', 'HMMT' ].includes(result.event);
      })
      .forEach((result) => {
        chartDataHM.push({ x: new Date(result.date), y: result.time_parsed });
      });

    this.results.data
      .filter((result) => {
        return [ 'Mar', 'MarMT' ].includes(result.event);
      })
      .forEach((result) => {
        chartDataMar.push({ x: new Date(result.date), y: result.time_parsed });
      });

    this.chart = new Chart('canvas', {
      type: 'line',
      data: {
        datasets: [
          // {
          //   data: chartDataMile,
          //   label: 'Mile',
          //   borderColor: '#fff',
          //   fill: false,
          // },
          // {
          //   data: chartData5K,
          //   label: '5K',
          //   borderColor: '#fff',
          //   fill: false,
          // },
          {
            data: chartData10K,
            label: '10K',
            borderColor: '#fff',
            fill: false,
          },
          // {
          //   data: chartDataHM,
          //   label: 'Half Marathon',
          //   borderColor: '#fff',
          //   fill: false,
          // },
          // {
          //   data: chartDataMar,
          //   label: 'Marathon',
          //   borderColor: '#fff',
          //   fill: false,
          // },
        ],
      },
      options: {
        maintainAspectRatio: false,
        scales: {
          xAxes: [
            {
              type: 'time',
              time: {
                unit: 'month',
              },
            },
          ],
          yAxes: [
            {
              ticks: {
                callback: function(value, index, values) {
                  return moment().add(value, 'seconds').format('m:ss');
                },
              },
            },
          ],
        },
        title: {
          display: false,
          text: 'Race history',
        },
      },
    });
  }
}
