import { useSearchParams } from "@solidjs/router";
import { useQuery } from "@tanstack/solid-query";
import { ApexOptions } from "apexcharts";
import { SolidApexCharts } from "solid-apexcharts";
import { createEffect, createSignal, onMount, Show } from "solid-js";
import { queryStats } from "../../api";
import { PageBase } from "../../layouts";
import { setPage } from "../../state/global";
import { setTitle } from "../../state/meta";
import { toaster } from "../../utils";
import { calculateTotals, findFirstCategorizedPoints, findMaxCount, Totals } from "./helper";
import Range from "./Range";
import StatsItem from "./StatsItem";

type Point = ServerData.StatsPoint;
type Status = ServerData.StatsStatus;
type Range = InputData.StatsRange;

const DEFAULT_RANGE: Range = "7d";
const COLORS = {
  passed: "#80FF97",
  rejected: "#FF8080",
  timeout: "#FFCB80",
  other: "#BBBBBB",
};

export default () => {
  const [searchParams, setSearchParams] = useSearchParams<{ range?: Range }>();
  const [empty, setEmpty] = createSignal<boolean>(true);
  const [totals, setTotals] = createSignal<Totals>({ passes: 0, fails: 0 });
  const [maxCount, setMaxCount] = createSignal<number>(10);
  const [categories, setCategories] = createSignal<string[]>([]);
  const [approvedData, setApprovedData] = createSignal<number[]>([]);
  const [incorrectData, setIncorrectData] = createSignal<number[]>([]);
  const [timeoutData, setTimeoutData] = createSignal<number[]>([]);
  const [statsOtherSeriesData, setStatsOtherSeriesData] = createSignal<number[]>([]);
  const query = useQuery(() => ({
    queryKey: ["stats", searchParams.range],
    queryFn: () => queryStats(searchParams.range || DEFAULT_RANGE),
  }));

  createEffect(() => {
    if (query.isSuccess && !query.data.success) {
      toaster.error({ title: "加载失败", description: `${query.data.message}，正在重定向...` });
      setSearchParams({ range: DEFAULT_RANGE });
      return;
    }

    if (query.data?.success) {
      const payload = query.data.payload;
      setTotals(calculateTotals(payload.points)); // 计算总数
      setMaxCount(findMaxCount(payload.points));
      const times: string[] = [];
      const categorizedPoints = findFirstCategorizedPoints(payload.points);
      if (categorizedPoints.length > 0) {
        setEmpty(false);
        categorizedPoints.forEach((p: ServerData.StatsPoint) => {
          times.push(p.time);
        });

        setCategories(times);
        setApprovedData(statusCount(payload.points, "approved"));
        setIncorrectData(statusCount(payload.points, "incorrect"));
        setTimeoutData(statusCount(payload.points, "timeout"));
        setStatsOtherSeriesData(statusCount(payload.points, "other"));
      } else {
        setEmpty(true);
      }
    }
  });

  const options: () => ApexOptions = () => {
    // 根据 `range` 的值动态决定 X 轴的时间格式
    let xaxisDateFormat;
    if ((searchParams.range || DEFAULT_RANGE) === "today") {
      // 格式化为时分秒
      xaxisDateFormat = "HH:mm:ss";
    } else {
      // 格式化为年月日
      xaxisDateFormat = "yyyy-MM-dd";
    }

    return {
      chart: { toolbar: { show: false }, zoom: { enabled: false } },
      xaxis: {
        type: "datetime",
        categories: categories(),
        labels: { show: true, datetimeUTC: false, format: xaxisDateFormat },
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
      colors: [COLORS.passed, COLORS.rejected, COLORS.timeout, COLORS.other],
    };
  };

  const series = (): ApexAxisChartSeries => [
    {
      name: "通过",
      data: approvedData(),
    },
    {
      name: "失败",
      data: incorrectData(),
    },
    {
      name: "超时",
      data: timeoutData(),
    },
    {
      name: "其它",
      data: statsOtherSeriesData(),
    },
  ];

  const statusCount = (points: Point[], status: Status): number[] => {
    if (query.data?.success) {
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

  onMount(() => {
    setTitle("仪表盘");
    setPage("dashboard");
  });

  return (
    <PageBase>
      <div>
        <Range hasDot active={searchParams.range === "today"} range="today">今日</Range>
        <Range hasDot active={!searchParams.range || searchParams.range === "7d"} range="7d">最近 7 天</Range>
        <Range hasDot active={searchParams.range === "30d"} range="30d">最近 30 天</Range>
        <Range active={searchParams.range === "all"} range="all">全部</Range>
      </div>
      <div class="mt-[1rem] grid grid-cols-3 gap-[1rem] py-[1rem] border-y border-line">
        <StatsItem
          title="验证总数"
          value={totals().passes + totals().fails}
          icon="lsicon:thumb-up-outline"
          color="darkturquoise"
        />
        <StatsItem
          title="验证通过"
          value={totals().passes}
          icon="material-symbols:check"
          color="darkseagreen"
          hasDivider
        />
        <StatsItem title="验证失败" value={totals().fails} icon="mdi:cancel" color="darkred" />
      </div>
      <div class="mt-[1rem] h-[40rem] bg-card rounded-2xl">
        <Show when={!empty()}>
          <SolidApexCharts
            width="95%"
            height="95%"
            type="area"
            options={options()}
            series={series()}
          />
        </Show>
      </div>
    </PageBase>
  );
};
