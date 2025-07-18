import { JSX } from "solid-js";

export default (props: { children: JSX.Element }) => {
  return (
    <main class="py-[1rem]">
      {props.children}
    </main>
  );
};
