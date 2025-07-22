import { Icon } from "@iconify-icon/solid";
import classNames from "classnames";

export default (props: { title: string; value: number; icon: string; color: string; hasDivider?: boolean }) => {
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
