import { ApexOptions } from "apexcharts";
import * as _ from "lodash";
import { SolidApexCharts } from "solid-apexcharts";
import { createEffect, createSignal, onMount } from "solid-js";
import { createStore } from "solid-js/store";
import useSWR from "solid-swr";
import { buildConsoleApiUrl, getter } from "../api";
import { useGlobalStore } from "../globalStore";
import { GeneralFrameBox } from "../layouts/Frame";

type Point = {
  time: string;
  status: string;
  count: number;
};
type QueryResult = {
  points: Point[];
};

type Range = "7d" | "30d";

type Dailies = {
  passed: number;
  rejected: number;
  timeout: number;
  other: number;
};

export default () => {
  const { store, setCurrentPage } = useGlobalStore();
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const [range, setRange] = createSignal<Range>("7d");
  const [statsCategories, setStatsCategories] = createSignal<string[]>([]);
  const [statsPasssedSeriesData, setStatsPasssedSeriesData] = createSignal<number[]>([]);
  const [statsRejectedSeriesData, setStatsRejectedSeriesData] = createSignal<number[]>([]);
  const [statsTimeoutSeriesData, setStatsTimeoutSeriesData] = createSignal<number[]>([]);
  const [statsOtherSeriesData, setStatsOtherSeriesData] = createSignal<number[]>([]);
  const [dailies, setDailies] = createStore<Dailies>({ passed: 0, rejected: 0, timeout: 0, other: 0 });
  const { data } = useSWR<QueryResult>(() => buildConsoleApiUrl(store.currentChat?.id, `/stats?range=${range()}`), {
    fetcher: getter,
  });
  const { data: daily } = useSWR<QueryResult>(() => buildConsoleApiUrl(store.currentChat?.id, `/stats?range=1d1d`), {
    fetcher: getter,
  });

  onMount(() => {
    setCurrentPage("dashboard");
  });

  createEffect(() => {
    if (data.v != null) {
      const times: string[] = [];
      data.v.points.filter((p) => p.status === "passed").forEach((p) => {
        times.push(p.time);
      });

      setStatsCategories(times);
      setStatsPasssedSeriesData(statusCounts(data.v.points, "passed"));
      setStatsRejectedSeriesData(statusCounts(data.v.points, "rejected"));
      setStatsTimeoutSeriesData(statusCounts(data.v.points, "timeout"));
      setStatsOtherSeriesData(statusCounts(data.v.points, "other"));
    }
  });

  createEffect(() => {
    if (daily.v != null) {
      setDailies("passed", _.sum(statusCounts(daily.v.points, "passed")));
      setDailies("rejected", _.sum(statusCounts(daily.v.points, "rejected")));
      setDailies("timeout", _.sum(statusCounts(daily.v.points, "timeout")));
      setDailies("other", _.sum(statusCounts(daily.v.points, "other")));
    }
  });

  const statusCounts = (points: Point[], status: string): number[] => {
    if (data.v != null) {
      return points.filter((p) => p.status === status).map((p) => {
        if (p.count == null) {
          return 0;
        } else {
          return p.count;
        }
      });
    }

    return [];
  };

  const statsOptions: () => ApexOptions = () => {
    return {
      chart: { toolbar: { show: false } },
      xaxis: {
        type: "datetime",
        categories: statsCategories(),
        labels: { show: true, datetimeUTC: false, format: "yyyy-MM-dd" },
      },
      tooltip: {
        x: {
          format: "yyyy/MM/dd HH:mm:ss",
        },
      },
    };
  };

  const statsSeries = (): ApexAxisChartSeries => [
    {
      name: "通过",
      data: statsPasssedSeriesData(),
    },
    {
      name: "失败",
      data: statsRejectedSeriesData(),
    },
    {
      name: "超时",
      data: statsTimeoutSeriesData(),
    },
    {
      name: "其它",
      data: statsOtherSeriesData(),
    },
  ];

  const Card = (props: { title: string; value: number }) => (
    <div tw="w-6/12 lg:flex-1 lg:h-full pb-4 odd:pr-1 even:pl-1 lg:odd:pr-4 lg:even:pl-0 lg:pr-4 lg:last:pr-0">
      <div tw="h-full bg-white/30 rounded-xl flex flex-col">
        <h2 tw="py-2 lg:py-4 text-center font-medium border-b border-black/20">{props.title}</h2>
        <div tw="flex-1 flex justify-center items-center">
          <p tw="font-bold text-3xl lg:text-4xl">{props.value}</p>
        </div>
        <p tw="text-center text-zinc-600 text-sm">今日</p>
      </div>
    </div>
  );

  return (
    <GeneralFrameBox>
      <div tw="h-full flex flex-col">
        <div tw="h-[50%] lg:h-[30%] flex flex-wrap justify-between">
          <Card title="验证通过" value={dailies.passed} />
          <Card title="验证失败" value={dailies.rejected} />
          <Card title="验证超时" value={dailies.timeout} />
          <Card title="其它" value={dailies.other} />
        </div>
        <div tw="flex-1 bg-white/30 rounded-xl">
          <header tw="p-3">
            <h2 tw="font-medium">验证次数统计（最近一周）</h2>
          </header>
          <SolidApexCharts
            width="95%"
            height="80%"
            type="line"
            options={statsOptions()}
            series={statsSeries()}
          />
        </div>
      </div>
    </GeneralFrameBox>
  );
};
