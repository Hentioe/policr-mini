import { ApexOptions } from "apexcharts";
import { SolidApexCharts } from "solid-apexcharts";
import { createEffect, createSignal, onMount } from "solid-js";
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

export default () => {
  const { store, setCurrentPage } = useGlobalStore();
  const [statsCategories, setStatsCategories] = createSignal<string[]>([]);
  const [statsPasssedSeriesData, setStatsPasssedSeriesData] = createSignal<number[]>([]);
  const [statsRejectedSeriesData, setStatsRejectedSeriesData] = createSignal<number[]>([]);
  const [statsTimeoutSeriesData, setStatsTimeoutSeriesData] = createSignal<number[]>([]);
  const [statsOtherSeriesData, setStatsOtherSeriesData] = createSignal<number[]>([]);
  const { data } = useSWR<QueryResult>(() => buildConsoleApiUrl(store.currentChat?.id, "/stats"), { fetcher: getter });

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
      setStatsPasssedSeriesData(statusCounts("passed"));
      setStatsRejectedSeriesData(statusCounts("rejected"));
      setStatsTimeoutSeriesData(statusCounts("timeout"));
      setStatsOtherSeriesData(statusCounts("other"));
    }
  });

  const statusCounts = (status: string): number[] => {
    if (data.v != null) {
      return data.v.points.filter((p) => p.status === status).map((p) => p.count);
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

  return (
    <GeneralFrameBox>
      <div tw="h-full flex flex-col">
        <div tw="h-[50%] lg:h-[30%]">
          {/* 单行多个数值数据卡片 */}
        </div>
        <div tw="flex-1 bg-white/30 rounded-xl">
          <header tw="p-3">
            <h2 tw="font-medium">验证次数统计（最近一周）</h2>
          </header>
          <SolidApexCharts
            width="100%"
            height="100%"
            type="line"
            options={statsOptions()}
            series={statsSeries()}
          />
        </div>
      </div>
    </GeneralFrameBox>
  );
};
