import { JSX } from "solid-js";

export default (props: { children: JSX.Element }) => {
  return <p class="my-[2rem] text-gray-400 text-lg text-center">{props.children}</p>;
};
