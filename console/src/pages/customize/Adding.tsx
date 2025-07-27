import { JSX } from "solid-js";
import Checkbox from "../../components/Checkbox";

const Root = (props: { children: JSX.Element }) => {
  return (
    <div class="flex flex-col gap-[0.85rem]">
      {props.children}
    </div>
  );
};

const Field = (props: { label: string; children: JSX.Element }) => {
  return (
    <div class="flex items-center">
      <span class="w-3/12">{props.label}</span>
      {props.children}
    </div>
  );
};

const Answer = (
  props: {
    label: string;
    value: string;
    correct?: boolean;
    onInput?: (value: string) => void;
    onCorrectChange?: (isCorrect: boolean) => void;
  },
) => {
  return (
    <div class="flex items-center">
      <span class="w-3/12">{props.label}</span>
      <div class="flex-1 flex justify-between gap-[1rem]">
        <Input placeholder="输入答案值" onInput={props.onInput} value={props.value} />
        <Checkbox label="正确" checked={props.correct} onChange={props.onCorrectChange} />
      </div>
    </div>
  );
};

const Input = (props: { placeholder: string; value?: string; onInput?: (value: string) => void }) => {
  const handleInput = (e: Event) => {
    const target = e.target as HTMLInputElement;
    props.onInput?.(target.value);
  };

  return (
    <input
      type="text"
      placeholder={props.placeholder}
      value={props.value || ""}
      onInput={handleInput}
      class="text-sm rounded-xl border-2 border-gray-200 p-2 flex-1"
    />
  );
};

export const Adding = {
  Root,
  Field,
  Input,
  Answer,
};
