import { Icon } from "@iconify-icon/solid";
import classNames from "classnames";
import { JSX, Match, Switch } from "solid-js";

type Variant = "info" | "danger";
type Props = {
  children: JSX.Element;
  variant?: Variant;
  size?: string;
  icon?: string;
  fullWidth?: boolean;
  disabled?: boolean;
  outline?: boolean;
  loading?: boolean;
  onClick?: () => void;
};

export default (props: Props) => {
  const renderStyle = () => {
    // 允许变化
    const allowChange = !props.disabled && !props.loading;
    if (props.outline) {
      switch (props.variant) {
        case "info":
          return classNames([
            "text-blue-500 border-blue-200 bg-blue-100/70",
            {
              "hover:bg-blue-200/80": allowChange,
            },
          ]);
        case "danger":
          return classNames([
            "text-red-500 border-red-200 bg-red-100/70",
            {
              "hover:bg-red-200/80": allowChange,
            },
          ]);
        default:
          return classNames([
            "text-zinc-500 border-zinc-200 bg-zinc-100/70",
            {
              "hover:bg-zinc-200/80": allowChange,
            },
          ]);
      }
    } else {
      switch (props.variant) {
        case "info":
          return classNames([
            "text-white bg-blue-500",
            {
              "hover:bg-blue-400": allowChange,
            },
          ]);
        case "danger":
          return classNames([
            "text-white bg-red-500",
            {
              "hover:bg-red-400": allowChange,
            },
          ]);
      }
    }
  };

  const iconSizeStyle = () => {
    switch (props.size) {
      case "sm":
        return "text-[1rem] w-[1rem] h-[1rem]";
      case "lg":
        return "text-[1.5rem] w-[1.5rem]";
      default:
        return "text-[1.25rem] w-[1.25rem] h-[1.25rem]"; // 默认大小
    }
  };

  const handleClick = () => {
    if (props.onClick && !props.disabled && !props.loading) {
      props.onClick();
    }
  };

  return (
    <button
      onClick={handleClick}
      class={classNames([
        "px-2 py-1 rounded-lg border transition-colors cursor-pointer select-none flex items-center",
        renderStyle(),
        {
          "cursor-not-allowed! opacity-50": props.disabled || props.loading,
          "w-full justify-center": props.fullWidth,
          "text-[0.85rem]": props.size === "sm",
          "text-base": !props.size || props.size === "md",
          "text-lg h-[2.5rem] px-4": props.size === "lg",
        },
      ])}
    >
      <Switch>
        <Match when={props.loading}>
          <Switch>
            <Match when={props.icon}>
              <div
                class={classNames([
                  "mr-1",
                  iconSizeStyle(),
                ])}
              >
                <Loading outline={props.outline} size={props.size} />
              </div>
              {props.children}
            </Match>
            <Match when={true}>
              <Loading outline={props.outline} size={props.size} />
            </Match>
          </Switch>
        </Match>
        <Match when={true}>
          {props.icon && (
            <Icon
              icon={props.icon}
              class={classNames([
                "mr-1",
                iconSizeStyle(),
              ])}
            />
          )}
          {props.children}
        </Match>
      </Switch>
    </button>
  );
};

const Loading = (props: { outline?: boolean; size?: string }) => {
  const sizeToRem = () => {
    switch (props.size) {
      case "sm":
        return "1rem";
      case "lg":
        return "1.5rem";
      default:
        return "1.25rem"; // 默认大小
    }
  };

  return (
    <svg xmlns="http://www.w3.org/2000/svg" width={sizeToRem()} height={sizeToRem()} viewBox="0 0 24 24">
      <path
        fill="none"
        stroke={props.outline ? "currentColor" : "#fff"}
        stroke-dasharray="16"
        stroke-dashoffset="16"
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width={2}
        d="M12 3c4.97 0 9 4.03 9 9"
      >
        <animate fill="freeze" attributeName="stroke-dashoffset" dur="0.06s" values="16;0" />
        <animateTransform
          attributeName="transform"
          dur="0.45s"
          repeatCount="indefinite"
          type="rotate"
          values="0 12 12;360 12 12"
        />
      </path>
    </svg>
  );
};
