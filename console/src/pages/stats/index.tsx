import { destructure } from "@solid-primitives/destructure";
import { useQuery } from "@tanstack/solid-query";
import { createSignal, onMount } from "solid-js";
import { queryStats } from "../../api";
import { Range } from "../../components";
import { PageBase } from "../../layouts";
import { globalState } from "../../state";
import { setCurrentPage } from "../../state/global";
import { setTitle } from "../../state/meta";
import AreaChart from "./AreaChart";
import TotalsView from "./TotalsView";

const DEFAULT_RANGE = "7d";
const RANGE_ITEMS: Array<{ value: InputData.StatsRange; label: string }> = [
  { value: "today", label: "今天" },
  { value: "7d", label: "最近 7 天" },
  { value: "28d", label: "最近 28 天" },
  { value: "90d", label: "最近 90 天" },
];

export default () => {
  const { currentChatId } = destructure(globalState);
  const [range, setRange] = createSignal<InputData.StatsRange>(DEFAULT_RANGE);

  const query = useQuery(() => ({
    queryKey: ["stats", currentChatId(), range()],
    queryFn: () => queryStats(currentChatId()!, range()),
    enabled: currentChatId() != null,
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
      <Range.List items={RANGE_ITEMS}>
        {(item) => (
          <Range.Item
            value={item.value}
            label={item.label}
            active={range() == item.value}
            onClick={handleRangeChange}
          />
        )}
      </Range.List>
      <TotalsView status={query.data?.success && query.data.payload} />
      <AreaChart range={range()} stats={query.data?.success && query.data.payload} />
    </PageBase>
  );
};
