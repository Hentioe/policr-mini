import { Icon } from "@iconify-icon/solid";
import { JSX } from "solid-js";

export default (props: { title: string; icon: string; children: JSX.Element }) => {
  return (
    <div class="pt-[0.5rem] pb-[1rem] bg-card border-l-4 border-blue-400 hover:border-blue-500 rounded shadow hover:shadow-lg hover:translate-x-[1px] hover:translate-y-[-1px] transition-all">
      <h2 class="pl-[1rem] py-[0.5rem] my-[1rem] text-lg bg-gray-200/60">
        <Icon inline icon={props.icon} class="w-[1.25rem] text-[1.25rem] mr-[0.5rem]" />
        {props.title}
      </h2>
      <div class="flex flex-col gap-[1rem] px-[1rem]">
        {props.children}
      </div>
    </div>
  );
};
