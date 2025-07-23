import { useQuery } from "@tanstack/solid-query";
import { createEffect, createSignal, For, onMount, Show } from "solid-js";
import { getTasks, resetStats } from "../../api";
import { ActionButton } from "../../components";
import { PageBase } from "../../layouts";
import { setPage } from "../../state/global";
import { setTitle } from "../../state/meta";
import { toaster } from "../../utils";
import Bee from "./Bee";
import Job from "./Job";

const REFETCH_INTERVAL = 3000; // 3 seconds

export default () => {
  const [jobsCount, setJobsCount] = createSignal(0);
  const [beesCount, setBeesCount] = createSignal(0);
  const [creatingReset, setCreatingReset] = createSignal(false);
  const [refetchInterval, setRefetchInterval] = createSignal<false | number>(REFETCH_INTERVAL);
  const query = useQuery(() => ({
    queryKey: ["tasks"],
    queryFn: getTasks,
    refetchInterval: refetchInterval(),
  }));

  const handleResetStats = async () => {
    setCreatingReset(true);
    const resp = await resetStats();
    setCreatingReset(false);
    if (resp.success) {
      toaster.success({ title: "重置任务创建成功", description: "请留意后台任务执行情况" });
    } else {
      toaster.error({ title: "重置任务创建失败", description: resp.message });
    }
  };

  createEffect(() => {
    if (query.data?.success) {
      const payload = query.data.payload;
      setJobsCount(payload.jobs.length);
      setBeesCount(payload.bees.length);
    }
  });

  // 其诶刷新状态
  const handleToggleRefetch = () => {
    if (refetchInterval()) {
      setRefetchInterval(false);
    } else {
      setRefetchInterval(REFETCH_INTERVAL);
    }
  };

  onMount(() => {
    setTitle("系统任务");
    setPage("tasks");
  });

  return (
    <PageBase>
      {/* 任务统计和功能按钮 */}
      <div class="my-[1rem] p-[1rem] bg-blue-100/40 text-gray-600 rounded-xl flex justify-between items-center card-edge border-l-4! border-l-blue-400!">
        <p>
          有 {jobsCount()} 个定时任务，和 {beesCount()} 个后台任务
        </p>
        <div class="flex gap-[0.5rem]">
          <ActionButton
            onClick={handleResetStats}
            loading={creatingReset()}
            icon="streamline-plump:eraser-remix"
            outline
          >
            重置统计数据
          </ActionButton>
          <ActionButton
            onClick={handleToggleRefetch}
            icon={refetchInterval() ? "hugeicons:stop" : "uil:play"}
            loading={query.isFetching}
            variant="danger"
            outline
          >
            {query.isFetching ? "正在刷新" : refetchInterval() ? "停止刷新" : "开始刷新"}
          </ActionButton>
        </div>
      </div>
      <Show when={query.data?.success && query.data.payload.bees.length > 0}>
        <div class="mb-[1rem] grid grid-cols-2 gap-[1rem]">
          <For each={query.data?.success && query.data.payload.bees || []}>
            {(bee) => (
              <Bee
                id={bee.id}
                status={bee.status}
                createdAt={bee.createdAt}
                expectedRunAt={bee.expectedRunAt}
                workStartedAt={bee.workStartedAt}
                workEndedAt={bee.workEndedAt}
                result={bee.result}
              />
            )}
          </For>
        </div>
      </Show>
      <div class="grid grid-cols-2 gap-[1rem]">
        <For each={query.data?.success && query.data.payload.jobs || []}>
          {(task) => (
            <Job
              id={task.id}
              title={task.name}
              period={task.period}
              scheduled={true}
              nextRunAt={task.nextRunAt}
            />
          )}
        </For>
      </div>
    </PageBase>
  );
};
