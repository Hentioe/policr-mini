import { onMount } from "solid-js";
import { PageBase } from "../layouts";
import { setPage } from "../state/global";
import { setTitle } from "../state/meta";

export default () => {
  onMount(() => {
    setTitle("系统任务");
    setPage("tasks");
  });

  return (
    <PageBase>
      <div class="grid grid-cols-3 gap-[1rem]">
        <Task title="过期检查" period="每 5 分钟" nextRun="2025-07-19 12:15:00" />
        <Task title="缓存清理" period="每 15 分钟" nextRun="2025-07-19 12:15:00" />
        <Task title="退出检查" period="每日" nextRun="2025-07-19 12:15:00" />
      </div>
      <p class="mt-[4rem] text-sm text-center text-gray-500 tracking-wide">
        定时任务是用于修正系统中存在的错误数据或状态的特殊任务，它们由系统自身创建和调度。
      </p>
    </PageBase>
  );
};

const Task = (props: { title: string; period: string; nextRun: string }) => {
  return (
    <div class="bg-zinc-100 card-edge">
      <h3 class="text-xl font-medium text-center py-[0.5rem] border-b border-zinc-300/80">{props.title}</h3>
      <div>
        <TaskField name="执行周期" value={props.period} />
        <TaskField name="下次运行时间" value={props.nextRun} />
      </div>
    </div>
  );
};

const TaskField = (props: { name: string; value: string }) => {
  return (
    <div class="py-[0.75rem] hover:bg-zinc-200">
      <p class="text-center font-medium">{props.name}</p>
      <p class="text-center mt-[0.25rem] text-zinc-500 tracking-wide">{props.value}</p>
    </div>
  );
};
