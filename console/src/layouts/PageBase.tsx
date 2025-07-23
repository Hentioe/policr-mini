import { JSX } from "solid-js";

export default (props: { children: JSX.Element }) => {
  return (
    <main class="py-[1rem] px-[1rem] text-foreground overflow-y-auto scrollbar">
      {props.children}
    </main>
  );
};
