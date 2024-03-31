import { JSXElement } from "solid-js";
import tw from "twin.macro";
import { useGlobalStore } from "../globalStore";

const Root = tw.div`w-full h-full`;

export default (props: { children: JSXElement }) => {
  const { store, draw } = useGlobalStore();
  let mainEl: HTMLDivElement | undefined;

  const handleDraw = () => {
    if (store.drawerOpen) {
      // 如果抽屉打开，点击主内容区域时关闭抽屉
      draw();
    }
  };

  return <Root ref={mainEl} onClick={handleDraw}>{props.children}</Root>;
};
