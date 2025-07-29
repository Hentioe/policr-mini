import { Icon } from "@iconify-icon/solid";
import classNames from "classnames";
import { Index, JSX, Show } from "solid-js";

type BadgeType = "success" | "error" | "info" | "warning";

const Badge = (props: { type: BadgeType; text: string }) => {
  return (
    <span
      class={classNames(
        "px-[0.5rem] py-[0.25rem] rounded text-xs",
        {
          "bg-green-100 text-green-800": props.type === "success",
          "bg-red-100 text-red-800": props.type === "error",
          "bg-blue-100 text-blue-800": props.type === "info",
          "bg-yellow-100 text-yellow-800": props.type === "warning",
        },
      )}
    >
      {props.text}
    </span>
  );
};

const Root = (props: { user: string; badge: JSX.Element; children: JSX.Element; bottoms: JSX.Element[] }) => {
  return (
    <div class="py-[0.85rem] border-b border-zinc-200 flex flex-col gap-[0.5rem]">
      {/* 用户名/徽章 */}
      <div class="flex items-center justify-between">
        <p class="flex items-center">
          <Icon icon="mdi:user-outline" class="text-zinc-400 text-[1.5rem] w-[1.5rem] mr-[0.5rem]" />
          {props.user}
        </p>
        {props.badge}
      </div>
      {/* 细节内容 */}
      {props.children}
      {/* 按钮或徽章列表 */}
      <Show when={props.bottoms.length > 0}>
        <div class="flex gap-[0.75rem]">
          <Index each={props.bottoms}>
            {(button) => <>{button()}</>}
          </Index>
        </div>
      </Show>
    </div>
  );
};

const Details = (props: { children: JSX.Element }) => {
  return (
    <div class="text-zinc-500 text-sm flex items-center gap-[0.5rem]">
      {props.children}
    </div>
  );
};

const Detail = (props: { text: string; icon: string }) => {
  return (
    <p class="flex items-center gap-[0.25rem]">
      <Icon icon={props.icon} />
      {props.text}
    </p>
  );
};

export const Record = {
  Root,
  Badge,
  Details,
  Detail,
};
