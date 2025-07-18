import { Icon } from "@iconify-icon/solid";
import { useQuery } from "@tanstack/solid-query";
import classNames from "classnames";
import { JSX, onMount } from "solid-js";
import { createStore } from "solid-js/store";
import { getTotals } from "../api";
import { PageBase } from "../layouts";
import { setTitle } from "../state/meta";

export default () => {
  const [totals, setTotals] = createStore<ServerData.Totals>({ all: 0, approved: 0, timedOut: 0 });
  const profileQuery = useQuery(() => ({
    queryKey: ["totals"],
    queryFn: () => getTotals(),
  }));

  onMount(async () => {
    if (profileQuery.data) {
      setTotals(profileQuery.data);
    }
  });

  onMount(() => {
    setTitle("仪表盘");
  });

  return (
    <PageBase>
      <div>
        <Range hasDot active>今日</Range>
        <Range hasDot>最近 7 天</Range>
        <Range hasDot>最近 30 天</Range>
        <Range>全部</Range>
      </div>
      <div class="mt-[1rem] grid grid-cols-3 gap-[1rem]">
        <StatsCard title="验证总数" total={totals.all} background="darkturquoise" />
        <StatsCard title="验证通过" total={totals.approved} background="darkseagreen" />
        <StatsCard title="验证失败" total={totals.timedOut} background="darkred" />
      </div>
    </PageBase>
  );
};

const StatsCard = (props: { title: string; total: number; background: string }) => {
  return (
    <div
      class="shadow rounded-lg bg-blue-400 text-zinc-100 text-center py-[2rem]"
      style={{ background: props.background }}
    >
      <h2 class="text-lg font-bold">
        {props.title}
      </h2>
      <p class="mt-[1rem] text-3xl font-medium">
        {props.total}
      </p>
    </div>
  );
};

const Range = (props: { children: JSX.Element; hasDot?: boolean; active?: boolean }) => {
  return (
    <>
      <a
        class={classNames([
          "text-blue-500 select-none cursor-pointer",
          {
            "text-zinc-700 cursor-not-allowed!": props.active,
          },
        ])}
      >
        {props.children}
      </a>
      {props.hasDot && <Icon inline icon="bi:dot" class="w-[1rem] text-zinc-400" />}
    </>
  );
};
