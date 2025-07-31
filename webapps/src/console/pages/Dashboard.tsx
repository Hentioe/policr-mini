import { ApexOptions } from "apexcharts";
import * as _ from "lodash";
import { SolidApexCharts } from "solid-apexcharts";
import { createEffect, createSignal, Match, onMount, Switch } from "solid-js";
import { createStore } from "solid-js/store";
import useSWR from "solid-swr";
import tinycolor from "tinycolor2";
import tw, { styled } from "twin.macro";
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

type RangeType = "7d" | "30d";

type Dailies = {
  approved: number;
  rejected: number;
  timeout: number;
  other: number;
};

const colors = {
  approved: "#80FF97",
  rejected: "#FF8080",
  timeout: "#FFCB80",
  other: "#BBBBBB",
};

const RangeOption = styled.li((ps: { active?: boolean }) => [
  tw`inline px-2 mx-1 rounded cursor-pointer select-none`,
  ps.active ? tw`bg-blue-500 text-white` : tw`hover:bg-blue-500/10`,
]);

function findMaxCount(points: Point[]): number {
  return _.max(points.map((p) => p.count));
}

function findFirstCategorizedPoints(points: Point[]): Point[] {
  const existsP = points.find((p) =>
    p.status === "approved" || p.status === "rejected" || p.status === "timeout" || p.status === "other"
  );

  if (existsP != null) {
    return points.filter((p) => p.status === existsP.status);
  }

  return [];
}

export default () => {
  const { store, setCurrentPage } = useGlobalStore();
  const [range, setRange] = createSignal<RangeType>("7d");
  const [maxCount, setMaxCount] = createSignal<number>(10);
  const [empty, setEmpty] = createSignal(false);
  const [statsCategories, setStatsCategories] = createSignal<string[]>([]);
  const [statsPasssedSeriesData, setStatsPasssedSeriesData] = createSignal<number[]>([]);
  const [statsRejectedSeriesData, setStatsRejectedSeriesData] = createSignal<number[]>([]);
  const [statsTimeoutSeriesData, setStatsTimeoutSeriesData] = createSignal<number[]>([]);
  const [statsOtherSeriesData, setStatsOtherSeriesData] = createSignal<number[]>([]);
  const [dailies, setDailies] = createStore<Dailies>({ approved: 0, rejected: 0, timeout: 0, other: 0 });
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
      setMaxCount(findMaxCount(data.v.points));

      const times: string[] = [];
      const categorizedPoints = findFirstCategorizedPoints(data.v.points);
      if (categorizedPoints.length > 0) {
        setEmpty(false);
        categorizedPoints.forEach((p: Point) => {
          times.push(p.time);
        });

        setStatsCategories(times);
        setStatsPasssedSeriesData(statusCounts(data.v.points, "approved"));
        setStatsRejectedSeriesData(statusCounts(data.v.points, "rejected"));
        setStatsTimeoutSeriesData(statusCounts(data.v.points, "timeout"));
        setStatsOtherSeriesData(statusCounts(data.v.points, "other"));
      } else {
        setEmpty(true);
      }
    }
  });

  createEffect(() => {
    if (daily.v != null) {
      setDailies("approved", _.sum(statusCounts(daily.v.points, "approved")));
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
      chart: { toolbar: { show: false }, zoom: { enabled: false } },
      xaxis: {
        type: "datetime",
        categories: statsCategories(),
        labels: { show: true, datetimeUTC: false, format: "yyyy-MM-dd" },
      },
      yaxis: {
        // 避免 y 轴显示小数（强制 max 值太小时步进为 1）
        stepSize: maxCount() < 10 ? 1 : undefined,
      },
      tooltip: {
        x: {
          format: "yyyy/MM/dd HH:mm:ss",
        },
      },
      colors: [colors.approved, colors.rejected, colors.timeout, colors.other],
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

  const TodayCard = (props: { title: string; value: number; baseColor: string }) => (
    <div tw="w-6/12 lg:flex-1 lg:h-full pb-4 odd:pr-1 even:pl-1 lg:odd:pr-4 lg:even:pl-0 lg:pr-4 lg:last:pr-0">
      <div tw="h-full bg-white/30 rounded-xl flex flex-col">
        <h2
          style={{ color: tinycolor(props.baseColor).darken(40) }}
          tw="py-2 lg:py-4 text-center font-medium border-b border-black/10"
        >
          {props.title}
        </h2>
        <div tw="flex-1 flex justify-center items-center">
          <p style={{ color: tinycolor(props.baseColor).darken(30) }} tw="font-bold text-3xl lg:text-4xl">
            {props.value}
          </p>
        </div>
        <p tw="text-center text-zinc-600 text-sm">今日</p>
      </div>
    </div>
  );

  return (
    <GeneralFrameBox>
      <div tw="h-full flex flex-col">
        <div tw="h-[50%] lg:h-[30%] flex flex-wrap justify-between">
          <TodayCard baseColor={colors.approved} title="验证通过" value={dailies.approved} />
          <TodayCard baseColor={colors.rejected} title="验证失败" value={dailies.rejected} />
          <TodayCard baseColor={colors.timeout} title="验证超时" value={dailies.timeout} />
          <TodayCard baseColor={colors.other} title="其它" value={dailies.other} />
        </div>
        <div tw="flex-1 bg-white/30 rounded-xl flex flex-col">
          <header tw="p-3 flex">
            <h2 tw="font-medium">验证次数统计</h2>
            <ul>
              <RangeOption active={range() === "7d"} onClick={() => setRange("7d")}>一周</RangeOption>
              <RangeOption active={range() === "30d"} onClick={() => setRange("30d")}>一个月</RangeOption>
            </ul>
          </header>
          <Switch>
            <Match when={!empty()}>
              <SolidApexCharts
                width="95%"
                height="80%"
                type="area"
                options={statsOptions()}
                series={statsSeries()}
              />
            </Match>
            <Match when={empty()}>
              <div tw="flex-1 flex justify-center items-center">
                <p tw="text-zinc-600/80 text-xl lg:text-2xl">没有统计数据</p>
              </div>
            </Match>
          </Switch>
        </div>
      </div>
    </GeneralFrameBox>
  );
};
