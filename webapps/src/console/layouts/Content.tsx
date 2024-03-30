import { JSXElement } from "solid-js";
import tw from "twin.macro";
import { useGlobalStore } from "../globalStore";

const Root = tw.div`w-full h-full`;

export default (props: { children: JSXElement }) => {
  const { draw } = useGlobalStore();
  let mainEl: HTMLDivElement | undefined;

  const handleDraw = () => draw();

  return <Root ref={mainEl} onClick={handleDraw}>{props.children}</Root>;
};
