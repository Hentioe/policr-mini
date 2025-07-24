import { destructure } from "@solid-primitives/destructure";
import classNames from "classnames";
import { createEffect } from "solid-js";
import { globalState } from "../state";
import { toggleDrawer } from "../state/global";

export default () => {
  const { drawerIsOpen } = destructure(globalState);

  const handleClick = () => {
    if (drawerIsOpen()) {
      // 仅在抽屉打开时响应事件
      toggleDrawer();
    }
  };

  createEffect(() => {
    // 禁用页面滚动
    if (drawerIsOpen()) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "";
    }
  });

  return (
    <div
      id="overlay"
      onClick={handleClick}
      class={classNames([
        "fixed inset-0 bg-black/30 transition-all duration-500",
        { "close": !drawerIsOpen(), "open": drawerIsOpen() },
      ])}
    />
  );
};
