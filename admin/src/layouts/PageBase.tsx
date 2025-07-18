import { JSX } from "solid-js";

export default (props: { children: JSX.Element }) => {
  return (
    <main>
      {props.children}
    </main>
  );
};
