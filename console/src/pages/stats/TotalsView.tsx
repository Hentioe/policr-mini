import { Icon } from "@iconify-icon/solid";
import classNames from "classnames";
import { createEffect, createSignal } from "solid-js";
import { calculateTotals, Totals } from "./helper";

export default (props: { status: ServerData.Stats | false | undefined }) => {
  const [totals, setTotals] = createSignal<Totals>(new Totals(0, 0));

  createEffect(() => {
    if (props.status) {
      setTotals(calculateTotals(props.status.points));
    }
  });

  return (
    <div class="mt-[1rem] grid grid-cols-3 py-[0.5rem] border-y border-zinc-200">
      <Item
        title="总数"
        value={totals().passes + totals().fails}
        icon="lsicon:thumb-up-outline"
        color="darkturquoise"
      />
      <Item
        title="通过"
        value={totals().passes}
        icon="material-symbols:check"
        color="darkseagreen"
        hasDivider
      />
      <Item title="禁止" value={totals().fails} icon="mdi:cancel" color="darkred" />
    </div>
  );
};

const Item = (props: { title: string; value: number; icon: string; color: string; hasDivider?: boolean }) => {
  return (
    <div
      class={classNames(
        ["flex justify-center items-center gap-[1rem] px-[1rem]"],
        {
          "border-x-[1px] border-zinc-200": props.hasDivider,
        },
      )}
    >
      <div>
        <div class="flex items-center gap-[0.5rem]">
          <div class="bg-zinc-100 h-[2.2rem] w-[2.25rem] rounded-full flex justify-center items-center">
            <Icon icon={props.icon} class="w-[1.5rem] h-[1.5rem] text-[1.5rem]" style={{ color: props.color }} />
          </div>
          <h2 class="font-medium">
            {props.title}
          </h2>
        </div>
        <p class="mt-[0.5rem] text-xl font-medium text-center">
          {props.value}
        </p>
      </div>
    </div>
  );
};
