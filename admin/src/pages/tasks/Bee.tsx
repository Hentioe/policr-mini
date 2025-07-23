import { Icon } from "@iconify-icon/solid";
import classNames from "classnames";
import { format } from "date-fns";
import { Show } from "solid-js";
import TaskField from "./TaskField";

type Props = {
  id: string;
  status: string;
  createdAt: Date;
  expectedRunAt: Date;
  workStartedAt?: Date;
  workEndedAt?: Date;
  result?: unknown;
};

const DATA_FORMAT = "yyyy-MM-dd HH:mm:ss";

const NAMES: { [key: string]: string } = {
  "reset_all_stats": "重置统计",
};

const ICONS: { [key: string]: string } = {
  "reset_all_stats": "streamline-plump-color:eraser",
};

const FALLBACK_ICON = "twemoji:construction-worker";

// 将状态映射为文字
const STATUS_TEXT: { [key: string]: string } = {
  pending: "等待中",
  running: "运行中",
  done: "已完成",
  raised: "已提升",
  terminated: "已终止",
  canceled: "已取消",
};

// 将状态颜色为颜色
const STATUS_COLOR: { [key: string]: string } = {
  pending: "text-yellow-500 bg-yellow-100",
  running: "text-blue-500 bg-blue-100",
  done: "text-green-500 bg-green-100",
  raised: "text-orange-500 bg-orange-100",
  terminated: "text-red-500 bg-red-100",
  canceled: "text-gray-500 bg-gray-100",
};

export default (props: Props) => {
  return (
    <div class="p-[2rem] bg-card card-edge">
      <Icon icon={ICONS[props.id] || FALLBACK_ICON} class="h-[3rem] text-[3rem] mr-[0.5rem] text-gray-600" />
      <h3 class="text-[1.5rem] font-medium py-[0.5rem] border-b border-zinc-300/80">
        {NAMES[props.id] || props.id}
      </h3>
      <div>
        <TaskField name="运行状态">
          <span
            class={classNames([
              "font-medium px-[1rem] py-1 rounded-2xl",
              STATUS_COLOR[props.status] || "text-gray-500 bg-gray-100",
            ])}
          >
            {STATUS_TEXT[props.status] || "未知状态"}
          </span>
        </TaskField>
        <TaskField name="创建于" value={format(props.createdAt, DATA_FORMAT)} />
        <Show when={props.workStartedAt}>
          <TaskField name="开始于">
            <span class="font-bold text-pink-400">{format(props.workStartedAt!, DATA_FORMAT)}</span>
          </TaskField>
        </Show>
        <Show when={props.workEndedAt}>
          <TaskField name="结束于" value={format(props.workEndedAt!, DATA_FORMAT)} />
        </Show>
        <Show when={props.result}>
          <pre class="mt-[0.75rem] text-sm font-mono text-gray-100 bg-gray-600 p-2 rounded">
            <code>
              {JSON.stringify(props.result, null, 2)}
            </code>
          </pre>
        </Show>
      </div>
    </div>
  );
};
