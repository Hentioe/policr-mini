import { JSX } from "solid-js";

export default (props: { label: string; children: JSX.Element }) => {
  return (
    <div>
      <span>{props.label}</span>
      <div class="mt-[0.5rem]">
        {props.children}
      </div>
    </div>
  );
};
