import { Icon } from "@iconify-icon/solid";
import classNames from "classnames";
import { JSX } from "solid-js";

export default (props: { children: JSX.Element; variant?: string; size?: string; icon?: string }) => {
  return (
    <button
      class={classNames([
        "px-2 py-1 rounded-lg border transition-colors cursor-pointer select-none flex items-center",
        {
          "text-[0.85rem]": props.size === "sm",
          "text-base": !props.size || props.size === "md",
          "text-zinc-500 border-zinc-200 bg-zinc-100/70 hover:bg-zinc-200/80": !props.variant,
          "text-blue-500 border-blue-200 bg-blue-100/70 hover:bg-blue-200/80": props.variant === "info",
          "text-red-500 border-red-200 bg-red-100/70 hover:bg-red-200/80": props.variant === "danger",
        },
      ])}
    >
      {props.icon && (
        <Icon
          icon={props.icon}
          class={classNames([
            "mr-1",
            { "text-[1.25rem] w-[1.25rem]": !props.size || props.size === "md" },
          ])}
        />
      )}
      {props.children}
    </button>
  );
};
