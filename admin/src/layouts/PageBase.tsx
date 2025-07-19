import { JSX } from "solid-js";

export default (props: { children: JSX.Element }) => {
  return (
    <main class="py-[1rem] px-[2rem]">
      {props.children}
    </main>
  );
};
