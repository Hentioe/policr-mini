import { Icon } from "@iconify-icon/solid";
import classNames from "classnames";
import { JSX } from "solid-js";

export default (props: { children: JSX.Element; hasDot?: boolean; active?: boolean; range: InputData.StatsRange }) => {
  return (
    <>
      <a
        href={`?range=${props.range}`}
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
