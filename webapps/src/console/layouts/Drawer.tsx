import { JSX, onMount } from "solid-js";
import tw, { styled } from "twin.macro";
import { useGlobalStore } from "../globalStore";

const Drawer = styled.div({
  boxShadow: `0 0 2px rgba(0,0,0,0.15)`,
  ...tw`h-full flex w-[20rem] absolute lg:relative left-[-20rem] lg:left-0 transition-all duration-500 z-50`,
});

export default (props: { children: JSX.Element }) => {
  const { setDrawerEl } = useGlobalStore();

  let drawer: HTMLDivElement | undefined;

  onMount(() => {
    if (drawer != null) {
      setDrawerEl(drawer);
    }
  });

  return (
    <Drawer ref={drawer}>
      {props.children}
    </Drawer>
  );
};
