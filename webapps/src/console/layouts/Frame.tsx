import { JSXElement } from "solid-js";
import tw from "twin.macro";

export const GeneralFrameBox = tw.main`p-2 lg:p-4`;

export default (props: { children?: JSXElement }) => {
  let frameEl: HTMLDivElement | undefined;

  return (
    <div ref={frameEl}>
      {props.children}
    </div>
  );
};
