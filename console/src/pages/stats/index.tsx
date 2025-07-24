import { useQuery } from "@tanstack/solid-query";
import { createSignal, onMount } from "solid-js";
import { queryStats } from "../../api";
import { PageBase } from "../../layouts";
import { setCurrentPage } from "../../state/global";
import { setTitle } from "../../state/meta";
import AreaChart from "./AreaChart";
import Range from "./Range";
import TotalsView from "./TotalsView";

const DEFAULT_RANGE = "7d";

export default () => {
  const [range, setRange] = createSignal<InputData.StatsRange>(DEFAULT_RANGE);

  const query = useQuery(() => ({
    queryKey: ["stats", range()],
    queryFn: () => queryStats(range()),
  }));

  const handleRangeChange = (newRange: InputData.StatsRange) => {
    setRange(newRange);
  };

  onMount(() => {
    setCurrentPage("stats");
    setTitle("统计");
  });

  return (
    <PageBase>
      <div class="flex justify-center">
        <Range onClick={handleRangeChange} hasDot active={range() === "today"} range="today">今日</Range>
        <Range onClick={handleRangeChange} hasDot active={range() === "7d"} range="7d">最近 7 天</Range>
        <Range onClick={handleRangeChange} hasDot active={range() === "28d"} range="28d">最近 28 天</Range>
        <Range onClick={handleRangeChange} active={range() === "90d"} range="90d">最近 90 天</Range>
      </div>
      <TotalsView status={query.data?.success && query.data.payload} />
      <AreaChart range={range()} stats={query.data?.success && query.data.payload} />
    </PageBase>
  );
};
