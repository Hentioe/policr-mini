import { JSX } from "solid-js";

export default (props: { label: string; children: JSX.Element }) => {
  return (
    <div class="flex items-center">
      <span class="w-[16rem]">{props.label}</span>
      <div class="flex-1">
        {props.children}
      </div>
    </div>
  );
};
