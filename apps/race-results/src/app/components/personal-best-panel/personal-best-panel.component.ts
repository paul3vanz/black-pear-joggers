import {
    AfterViewInit,
    ChangeDetectionStrategy,
    Component,
    Input,
    OnChanges
    } from '@angular/core';
import { Chart, ChartPoint } from 'chart.js';
import { LoadingState, Result } from '@black-pear-joggers/race-results-data-access';
import { PacePipe } from 'libs/shared-pipes/src/lib/pipes/pace.pipe';
import { Paging } from '../../models/paging';
import { Ranking } from '../../../../../../libs/race-results-data-access/src/lib/models/ranking.model';
import { YearRankingStats } from 'libs/race-results-data-access/src/lib/models/ranking-stats.model';


interface PerformanceChartPoint extends ChartPoint {
    time?: number;
    event?: string;
}
@Component({
    selector: 'bpj-personal-best-panel',
    templateUrl: './personal-best-panel.component.html',
    styleUrls: ['./personal-best-panel.component.scss'],
    changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PersonalBestPanelComponent implements OnChanges, AfterViewInit {
    @Input() eventName = '5K';
    @Input() loadingState: LoadingState;
    @Input() personalBests: any;
    @Input() rankings: Ranking[];
    @Input() rankingsStats: YearRankingStats[];
    @Input() results: Paging<Result>;
    chart: Chart;

    chartDefaults: Chart.ChartDataSets = {
        radius: 3,
        fill: false,
        cubicInterpolationMode: 'monotone',
        lineTension: 0,
    };

    constructor(private pacePipe: PacePipe) { }

    ngAfterViewInit() {
        this.chart = new Chart('canvas', {
            type: 'line',
            data: {},
            options: {
                maintainAspectRatio: false,
                legend: {
                    position: 'bottom',
                },
                tooltips: {
                    mode: 'nearest',
                    intersect: false,
                    callbacks: {
                        title: (tooltipItem, data) => {
                            const chartPoint = <PerformanceChartPoint>data.datasets[tooltipItem[0].datasetIndex].data[tooltipItem[0].index];
                            return chartPoint.event || new Date(<string>chartPoint.x).toDateString();
                        },
                        label: (tooltipItem, data) => {
                            const dataItem = <PerformanceChartPoint>data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index];

                            if (dataItem.time) {
                                const finishTime = dataItem.time;
                                const event = data.datasets[tooltipItem.datasetIndex].label;
                                const formattedTime = this.formattedTime(finishTime);
                                const pace = this.pacePipe.transform(finishTime, event);

                                return `${formattedTime} (${pace})`;
                            } else {
                                return `${dataItem.y}`;
                            }
                        },
                    },
                },
                scales: {
                    xAxes: [
                        {
                            type: 'time',
                            time: {
                                unit: 'month',
                            },
                            ticks: { maxRotation: 0, autoSkip: true, autoSkipPadding: 20 },
                        },
                    ],
                    yAxes: [
                        {
                            id: 'personalBests',
                            display: false,
                            ticks: {
                                callback: () => {
                                    return null;
                                },
                            },
                        },
                        {
                            id: 'rankings',
                            display: false,
                            ticks: {
                                reverse: true,
                                callback: () => {
                                    return null;
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

    ngOnChanges(changes) {
        if (!this.results || !this.results.data || !this.rankings || !this.chart) {
            return;
        }

        const chartDataRankings: ChartPoint[] = [];
        const chartData5K: PerformanceChartPoint[] = [];
        const chartData10K: PerformanceChartPoint[] = [];
        const chartDataHM: PerformanceChartPoint[] = [];
        const chartDataMar: PerformanceChartPoint[] = [];

        this.rankings.forEach((ranking) => {
            chartDataRankings.push({
                x: new Date(ranking.date),
                y: ranking.ranking,
            });
        });

        this.get5K().forEach((result) => {
            chartData5K.push({
                x: new Date(result.date),
                y: this.pacePipe.transform(result.timeParsed, '5K', true),
                time: result.timeParsed,
                event: result.meetingName,
            });
        });

        this.get10K().forEach((result) => {
            chartData10K.push({
                x: new Date(result.date),
                y: this.pacePipe.transform(result.timeParsed, '10K', true),
                time: result.timeParsed,
                event: result.meetingName,
            });
        });

        this.getHM().forEach((result) => {
            chartDataHM.push({
                x: new Date(result.date),
                y: this.pacePipe.transform(result.timeParsed, 'Half Marathon', true),
                time: result.timeParsed,
                event: result.meetingName,
            });
        });

        this.getMar().forEach((result) => {
            chartDataMar.push({
                x: new Date(result.date),
                y: this.pacePipe.transform(result.timeParsed, 'Marathon', true),
                time: result.timeParsed,
                event: result.meetingName,
            });
        });

        this.chart.data = {
            datasets: [
                this.createDataSet(chartDataRankings, 'Ranking', '#222222', {
                    borderWidth: 1,
                    borderDash: [2, 2],
                    radius: 0,
                    order: 1,
                    fill: false,
                    backgroundColor: '#fff',
                    yAxisID: 'rankings',
                }),
                this.createDataSet(chartData5K, '5K', '#f89829'),
                this.createDataSet(chartData10K, '10K', '#ccc'),
                this.createDataSet(chartDataHM, 'Half Marathon', '#999'),
                this.createDataSet(chartDataMar, 'Marathon', '#000'),
            ],
        };

        this.chart.update();
    }

    formattedTime(timeInSeconds: number) {
        return new Date(timeInSeconds * 1000)
            .toISOString()
            .substr(11, 8)
            .toString()
            .substring(timeInSeconds >= 3600 ? 1 : 3);
    }

    get5K() {
        return this.results.data.filter((result) => {
            return ['5K', 'parkrun'].includes(result.event) && result.isPersonalBest;
        });
    }

    get10K() {
        return this.results.data.filter((result) => {
            return ['10K', '10KMT'].includes(result.event) && result.isPersonalBest;
        });
    }

    getHM() {
        return this.results.data.filter((result) => {
            return ['HM', 'HMMT'].includes(result.event) && result.isPersonalBest;
        });
    }

    getMar() {
        return this.results.data.filter((result) => {
            return ['Mar', 'MarMT'].includes(result.event) && result.isPersonalBest;
        });
    }

    createDataSet(data: ChartPoint[], label: string, colour: string, optionOverrides?: Chart.ChartDataSets): Chart.ChartDataSets {
        return {
            data: data,
            label,
            borderColor: colour,
            backgroundColor: colour,
            ...this.chartDefaults,
            ...optionOverrides,
        };
    }
}
