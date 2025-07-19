import { Icon } from "@iconify-icon/solid";
import { useQuery } from "@tanstack/solid-query";
import classNames from "classnames";
import { createEffect, JSX, onMount } from "solid-js";
import { createStore } from "solid-js/store";
import { getStats } from "../api";
import { PageBase } from "../layouts";
import { setPage } from "../state/global";
import { setTitle } from "../state/meta";

export default () => {
  const [stats, setStats] = createStore<ServerData.Stats>({ verification: { total: 0, approved: 0, rejected: 0 } });
  const statsQuery = useQuery(() => ({
    queryKey: ["stats"],
    queryFn: () => getStats(),
  }));

  createEffect(() => {
    if (statsQuery.data?.success) {
      setStats(statsQuery.data.payload);
    }
  });

  onMount(() => {
    setTitle("仪表盘");
    setPage("dashboard");
  });

  return (
    <PageBase>
      <div>
        <Range hasDot active>今日</Range>
        <Range hasDot>最近 7 天</Range>
        <Range hasDot>最近 30 天</Range>
        <Range>全部</Range>
      </div>
      <div class="mt-[1rem] grid grid-cols-3 gap-[1rem] py-[1rem] border-y border-zinc-200">
        <StatsItem
          title="验证总数"
          value={stats.verification.total}
          icon="lsicon:thumb-up-outline"
          color="darkturquoise"
        />
        <StatsItem
          title="验证通过"
          value={stats.verification.approved}
          icon="material-symbols:check"
          color="darkseagreen"
          hasDivider
        />
        <StatsItem title="验证失败" value={stats.verification.rejected} icon="mdi:cancel" color="darkred" />
      </div>
    </PageBase>
  );
};

const StatsItem = (props: { title: string; value: number; icon: string; color: string; hasDivider?: boolean }) => {
  return (
    <div
      class={classNames(
        ["flex justify-center items-center gap-[1rem] px-[1rem]"],
        {
          "border-x-[1px] border-zinc-200": props.hasDivider,
        },
      )}
    >
      <div class="rounded-full bg-zinc-100 h-[3rem] w-[3rem] flex justify-center items-center">
        <Icon icon={props.icon} class="w-[2rem] h-[2rem] text-[2rem]" style={{ color: props.color }} />
      </div>
      <div>
        <h2 class="font-medium">
          {props.title}
        </h2>
        <p class="mt-[1rem] text-xl font-bold">
          {props.value}
        </p>
      </div>
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
