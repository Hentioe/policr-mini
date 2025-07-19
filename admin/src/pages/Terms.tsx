import { onMount } from "solid-js";
import { PageBase } from "../layouts";
import { setPage } from "../state/global";
import { setTitle } from "../state/meta";

export default () => {
  onMount(() => {
    setTitle("使用条款");
    setPage("terms");
  });

  return (
    <PageBase>
      <textarea class="w-full h-[34rem] card-edge focus:outline-2 focus:outline-blue-400 p-[1rem]">
        这是使用条款的内容。
      </textarea>
      <button class="mt-[1rem] w-full bg-blue-400 hover:bg-blue-500 text-white font-bold rounded-2xl cursor-pointer py-[0.5rem] text-center">
        保存
      </button>
    </PageBase>
  );
};
