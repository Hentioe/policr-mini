import { Icon } from "@iconify-icon/solid";
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
        <OptionGroup title="验证配置" icon="fluent-color:lock-shield-16">
          <SelectOption lable="验证方式" placeholder="选择一个验证方式" />
          <SelectOption lable="击杀方式（验证超时）" placeholder="选择一个击杀方法" />
          <SelectOption lable="击杀方式（验证错误）" placeholder="选择一个击杀方法" />
        </OptionGroup>
        <OptionGroup title="时间配置" icon="twemoji:hourglass-not-done">
          <InputOption lable="等待时长（超时）" placeholder="输入数值（秒）" type="number" />
          <InputOption lable="解封延时" placeholder="输入数值（秒）" type="number" />
        </OptionGroup>
        <OptionGroup title="显示配置" icon="streamline-plump-color:eye-optic">
          <SelectOption lable="提及文本" placeholder="选择提及文本" />
          <SelectOption lable="答案个数（图片验证）" placeholder="选择答案个数" />
        </OptionGroup>
        <OptionGroup title="其它" icon="twemoji:hammer-and-wrench">
          <OptionRoot lable="服务消息清理">
            <div class="flex gap-[1rem]">
              <Checkbox label="加入群组" />
              <Checkbox label="退出群组" />
            </div>
          </OptionRoot>
        </OptionGroup>
      </div>
    </PageBase>
  );
};

const OptionGroup = (props: { title: string; icon: string; children: JSX.Element }) => {
  return (
    <div class="pt-[0.5rem] pb-[1rem] bg-white border-l-4 border-blue-400 shadow hover:shadow-lg rounded transition-all">
      <h2 class="pl-[1rem] py-[0.5rem] my-[1rem] text-lg bg-gray-200">
        <Icon inline icon={props.icon} class="w-[1.25rem] text-[1.25rem] mr-[0.5rem]" />
        {props.title}
      </h2>
      <div class="flex flex-col gap-[1rem] px-[1rem]">
        {props.children}
      </div>
    </div>
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
        class="w-full h-[2.5rem] px-[1rem] outline-0 input-edge focus:outline-2 outline-blue-400"
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
      <span class="w-[16rem]">{props.lable}</span>
      <div class="flex-1">
        {props.children}
      </div>
    </div>
  );
};
