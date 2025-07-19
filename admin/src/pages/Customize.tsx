import { createSignal, JSX, onMount } from "solid-js";
import { Select } from "../components";
import { PageBase } from "../layouts";
import { setPage } from "../state/global";
import { setTitle } from "../state/meta";

export default () => {
  onMount(() => {
    setTitle("全局调整");
    setPage("customize");
  });

  return (
    <PageBase>
      <div class="flex flex-col gap-[1.5rem]">
        <SelectOption lable="验证方式" placeholder="选择一个验证方式" />
        <SelectOption lable="击杀方式（验证超时）" placeholder="选择一个击杀方法" />
        <SelectOption lable="击杀方式（验证错误）" placeholder="选择一个击杀方法" />
        <InputOption lable="超时时长" placeholder="输入数值" type="number" />
        <SelectOption lable="提及文本" placeholder="选择提及文本" />
        <InputOption lable="解封延时" placeholder="输入数值" type="number" />
        <SelectOption lable="答案个数（图片验证）" placeholder="选择答案个数" />
        <OptionRoot lable="服务消息清理">
          <div class="flex gap-[1rem]">
            <Checkbox label="加入群组" />
            <Checkbox label="退出群组" />
          </div>
        </OptionRoot>
      </div>
    </PageBase>
  );
};

const SelectOption = (props: { lable: string; placeholder: string }) => {
  return (
    <OptionRoot lable={props.lable}>
      <Select placeholder={props.placeholder} />
    </OptionRoot>
  );
};

const InputOption = (
  props: { lable: string; placeholder: string; type?: JSX.InputHTMLAttributes<HTMLInputElement>["type"] },
) => {
  return (
    <OptionRoot lable={props.lable}>
      <input
        placeholder={props.placeholder}
        type={props.type || "text"}
        class="w-full h-[2.5rem] px-[1rem] outline-0 border border-zinc-200 shadow rounded focus:outline-2 outline-blue-400"
      />
    </OptionRoot>
  );
};

const Checkbox = (props: { label: string }) => {
  const [checked, setChecked] = createSignal(false);
  const toggleChecked = () => setChecked(!checked());

  return (
    <div class="flex items-center gap-[0.5rem] select-none cursor-pointer" onClick={toggleChecked}>
      <span>{props.label}</span>
      <input
        type="checkbox"
        checked={checked()}
        class="w-[1rem] h-[1rem] outline-0 border border-zinc-200 shadow rounded"
      />
    </div>
  );
};

const OptionRoot = (props: { lable: string; children: JSX.Element }) => {
  return (
    <div class="flex items-center">
      <span class="w-[16rem] text-lg">{props.lable}</span>
      <div class="flex-1">
        {props.children}
      </div>
    </div>
  );
};
