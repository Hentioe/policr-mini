import { JSXElement } from "solid-js";
import tw from "twin.macro";

export const GeneralFrameBox = tw.main`p-2 lg:p-4 h-full`;

export default (props: { children?: JSXElement }) => {
  let frameEl: HTMLDivElement | undefined;

  return (
    <div tw="flex-1" ref={frameEl}>
      {props.children}
    </div>
  );
};
