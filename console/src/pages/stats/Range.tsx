import { Icon } from "@iconify-icon/solid";
import classNames from "classnames";
import { JSX } from "solid-js";

export default (
  props: {
    children: JSX.Element;
    hasDot?: boolean;
    active?: boolean;
    range: InputData.StatsRange;
    onClick?: (range: InputData.StatsRange) => void;
  },
) => {
  const handleClick = () => {
    if (props.onClick && !props.active) {
      props.onClick(props.range);
    }
  };

  return (
    <div onClick={handleClick} class="flex items-center">
      <span
        class={classNames([
          "text-blue-500 select-none cursor-pointer",
          {
            "text-zinc-700 cursor-not-allowed!": props.active,
          },
        ])}
      >
        {props.children}
      </span>
      {props.hasDot && <Icon inline icon="bi:dot" class="w-[1rem] text-zinc-400" />}
    </div>
  );
};
