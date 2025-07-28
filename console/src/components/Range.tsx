// 此组件依赖外部样式 styles/components/range.css

import classNames from "classnames";
import { Index, JSX } from "solid-js";

type Item<T> = {
  value: T;
  label: string;
};

const List = <T,>(props: { items: Item<T>[]; children: (range: Item<T>) => JSX.Element }) => {
  return (
    <div class="flex justify-center">
      <Index each={props.items}>
        {range => <>{props.children(range())}</>}
      </Index>
    </div>
  );
};

const Item = <T,>(
  props: {
    value: T;
    label: string;
    active?: boolean;
    onClick?: (value: T) => void;
  },
) => {
  const handleClick = () => {
    if (props.onClick && !props.active) {
      props.onClick(props.value);
    }
  };

  return (
    <div onClick={handleClick} class="range flex items-center">
      <span
        class={classNames([
          "text-blue-500 select-none cursor-pointer",
          {
            "text-zinc-700 cursor-not-allowed!": props.active,
          },
        ])}
      >
        {props.label}
      </span>
    </div>
  );
};

export const Range = {
  List,
  Item,
};
