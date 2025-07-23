import { Icon } from "@iconify-icon/solid";
import { format } from "date-fns";
import { Match, Switch } from "solid-js";
import TaskField from "./TaskField";

const ICONS: { [key: string]: string } = {
  "expired_check": "flat-color-icons:expired",
  "left_check": "streamline-color:emergency-exit-flat",
  "cache_clean": "streamline-plump-color:clean-broom-wipe-flat",
};

const FALLBACK_ICON = "mdi:airplane-schedule";

type Props = {
  id: string;
  title: string;
  period: string;
  scheduled: boolean;
  nextRunAt: Date;
};

export default (props: Props) => {
  return (
    <div class="p-[2rem] bg-card card-edge">
      <Icon icon={ICONS[props.id] || FALLBACK_ICON} class="h-[3rem] text-[3rem] mr-[0.5rem] text-gray-600" />
      <h3 class="text-[1.5rem] font-medium py-[0.5rem] border-b border-zinc-300/80">
        {props.title}
      </h3>
      <div>
        <TaskField name="执行周期" value={props.period} />
        <TaskField name="运行状态">
          <Switch>
            <Match when={props.scheduled}>
              <span class="text-blue-500 bg-blue-100 font-medium px-[1rem] py-1 rounded-2xl">
                已调度
              </span>
            </Match>
            <Match when={true}>
              <span class="text-yellow-500 bg-yellow-100 font-medium px-[1rem] py-1 rounded-2xl">
                未调度
              </span>
            </Match>
          </Switch>
        </TaskField>
        <TaskField name="上次运行" value="2025-07-19 12:10:00" />
        <TaskField name="下次运行">
          <span class="font-bold text-pink-400">{format(props.nextRunAt, "yyyy-MM-dd HH:mm:ss")}</span>
        </TaskField>
      </div>
    </div>
  );
};
