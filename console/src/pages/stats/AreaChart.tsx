import { ApexOptions } from "apexcharts";
import { SolidApexCharts } from "solid-apexcharts";
import { createEffect, createSignal, JSX, Match, Switch } from "solid-js";
import Loading from "../../components/Loading";
import { calculateTotals, findFirstCategorizedPoints, findMaxCount, statusCount } from "./helper";

const COLORS = {
  approved: "#80FF97",
  rejected: "#FF8080",
  timeout: "#FFCB80",
  other: "#BBBBBB",
};

export default (props: { range: InputData.StatsRange; stats: ServerData.Stats | false | undefined }) => {
  const [empty, setEmpty] = createSignal<boolean>(true);
  const [loading, setLoading] = createSignal<boolean>(true);
  const [maxCount, setMaxCount] = createSignal<number>(10);
  const [categories, setCategories] = createSignal<string[]>([]);
  const [approvedData, setApprovedData] = createSignal<number[]>([]);
  const [incorrectData, setIncorrectData] = createSignal<number[]>([]);
  const [timeoutData, setTimeoutData] = createSignal<number[]>([]);
  const [statsOtherSeriesData, setStatsOtherSeriesData] = createSignal<number[]>([]);

  createEffect(() => {
    if (props.stats) {
      setLoading(false);
      if (calculateTotals(props.stats.points).isEmpty()) {
        setEmpty(true);
      } else {
        setMaxCount(findMaxCount(props.stats.points));
        const times: string[] = [];
        const categorizedPoints = findFirstCategorizedPoints(props.stats.points);
        if (categorizedPoints.length > 0) {
          categorizedPoints.forEach((p: ServerData.StatsPoint) => {
            times.push(p.time);
          });

          setCategories(times);
          setApprovedData(statusCount(props.stats.points, "approved"));
          setIncorrectData(statusCount(props.stats.points, "incorrect"));
          setTimeoutData(statusCount(props.stats.points, "timeout"));
          setStatsOtherSeriesData(statusCount(props.stats.points, "other"));
        }
        setEmpty(false);
      }
    } else {
      setLoading(true);
    }
  });

  const options: () => ApexOptions = () => {
    // 根据 `range` 的值动态决定 X 轴的时间格式
    let xaxisDateFormat;
    switch (props.range) {
      case "today":
        xaxisDateFormat = "HH:mm";
        break;
      case "7d":
      case "28d":
        xaxisDateFormat = "MM-dd";
        break;
      default:
        xaxisDateFormat = "yyyy-MM-dd";
        break;
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
      dataLabels: { enabled: false },
      colors: [COLORS.approved, COLORS.rejected, COLORS.timeout, COLORS.other],
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

  return (
    <Root>
      <Switch>
        <Match when={empty()}>
          <Switch>
            <Match when={loading()}>
              <MyLoading />
            </Match>
            <Match when={empty()}>
              <Empty />
            </Match>
          </Switch>
        </Match>
        <Match when={true}>
          <SolidApexCharts
            width="100%"
            height="100%"
            type="area"
            options={options()}
            series={series()}
          />
        </Match>
      </Switch>
    </Root>
  );
};

const Root = (props: { children: JSX.Element }) => {
  return <div class="mx-edge-neg mt-[1rem] h-[24rem] bg-card rounded-2xl">{props.children}</div>;
};

const MyLoading = () => {
  return (
    <div class="flex items-center justify-center mt-[2rem]">
      <Loading size="xl" color="skyblue" />
    </div>
  );
};

const Empty = () => {
  return <p class="mt-[2rem] text-center text-zinc-600 text-lg">暂无数据</p>;
};
