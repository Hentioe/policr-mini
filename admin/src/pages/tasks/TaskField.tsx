import { JSX } from "solid-js";

export default (props: { children?: JSX.Element; name: string; value?: string }) => {
  return (
    <div class="py-[0.75rem] flex justify-between">
      <span class="text-zinc-500 font-medium">{props.name}</span>
      {props.children ? props.children : <span class="text-zinc-600 font-bold">{props.value}</span>}
    </div>
  );
};
