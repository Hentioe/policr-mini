import { Icon } from "@iconify-icon/solid";
import { JSX, onMount } from "solid-js";
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
      <div class="grid grid-cols-2 gap-[1rem]">
        <Task title="过期检查" icon="flat-color-icons:expired" period="每 5 分钟" nextRun="2025-07-19 12:15:00" />
        <Task
          title="缓存清理"
          icon="streamline-plump-color:clean-broom-wipe-flat"
          period="每 15 分钟"
          nextRun="2025-07-19 12:15:00"
        />
        <Task
          title="退出检查"
          icon="streamline-color:emergency-exit-flat"
          period="每日"
          nextRun="2025-07-19 12:15:00"
        />
      </div>
      <p class="mt-[4rem] text-sm text-center text-gray-500 tracking-wide">
        定时任务是用于修正系统中存在的错误数据或状态的特殊任务，它们由系统自身创建和调度。
      </p>
    </PageBase>
  );
};

const Task = (props: { title: string; icon: string; period: string; nextRun: string }) => {
  return (
    <div class="bg-zinc-50 p-[2rem] card-edge">
      <Icon icon={props.icon} class="h-[3rem] text-[3rem] mr-[0.5rem] text-gray-600" />
      <h3 class="text-[1.5rem] font-medium py-[0.5rem] border-b border-zinc-300/80">
        {props.title}
      </h3>
      <div>
        <TaskField name="执行周期" value={props.period} />
        <TaskField name="运行状态">
          <span class="text-blue-500 bg-blue-100 font-medium px-[1rem] py-1 rounded-2xl">已调度</span>
        </TaskField>
        <TaskField name="上次运行" value="2025-07-19 12:10:00" />
        <TaskField name="下次运行">
          <span class="font-bold text-pink-400">{props.nextRun}</span>
        </TaskField>
      </div>
    </div>
  );
};

const TaskField = (props: { children?: JSX.Element; name: string; value?: string }) => {
  return (
    <div class="py-[0.75rem] flex justify-between">
      <span class="text-zinc-500 font-medium">{props.name}</span>
      {props.children ? props.children : <span class="text-zinc-600 font-bold">{props.value}</span>}
    </div>
  );
};
