import { JSX } from "solid-js";

export default (props: { children: JSX.Element }) => {
  return (
    <main class="pt-main-top pb-main-bottom min-h-screen bg-white px-edge text-foreground overflow-y-auto">
      {props.children}
    </main>
  );
};
