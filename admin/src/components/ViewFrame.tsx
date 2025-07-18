import classNames from "classnames";
import { JSX } from "solid-js";
import { Dynamic } from "solid-js/web";

export default (props: { children: JSX.Element; as?: string; bg?: string; bgNoFill?: boolean }) => {
  return (
    // 此处的根容器用于设置视图独有的样式，如背景
    <Dynamic
      component={props.as || "section"}
      class={classNames([
        "w-full smart-bg",
        {
          "fill-bg": !props.bgNoFill,
          "width-bg": props.bgNoFill,
        },
      ])}
      style={{ "background-image": props.bg ? `url("${props.bg}")` : undefined }}
    >
      <div class="w-full 2xl:w-max-view px-[1rem] md:px-[4rem] mx-auto">
        {props.children}
      </div>
    </Dynamic>
  );
};
