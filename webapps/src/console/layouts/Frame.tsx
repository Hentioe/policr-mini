import { JSXElement } from "solid-js";
import tw, { styled } from "twin.macro";
import { useGlobalStore } from "../globalStore";

const Root = styled.div((ps: { blur: boolean }) => [
  ps.blur && tw`blur`,
]);

export const GeneralFrameBox = tw.main`p-2 lg:p-4`;

export default (props: { children?: JSXElement }) => {
  const { store } = useGlobalStore();
  let frameEl: HTMLDivElement | undefined;

  return (
    <Root ref={frameEl} blur={store.drawerOpen || false}>
      {props.children}
    </Root>
  );
};
