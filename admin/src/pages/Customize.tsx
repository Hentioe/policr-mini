import { Icon } from "@iconify-icon/solid";
import { useQuery } from "@tanstack/solid-query";
import { createEffect, createSignal, JSX, onMount } from "solid-js";
import { getCustomize } from "../api";
import { Select } from "../components";
import { PageBase } from "../layouts";
import { setPage } from "../state/global";
import { setTitle } from "../state/meta";

type Scheme = ServerData.Scheme;

export default () => {
  const [type, setType] = createSignal<Scheme["type"] | undefined>(undefined);
  const [typeItems, setTypeItems] = createSignal<Scheme["typeItems"]>([]);
  const [timeout, setTimeout] = createSignal<Scheme["timeout"] | undefined>(undefined);
  const [killStrategy, setKillStrategy] = createSignal<Scheme["killStrategy"] | undefined>(undefined);
  const [fallbackKillStrategy, setFallbackKillStrategy] = createSignal<Scheme["fallbackKillStrategy"] | undefined>(
    undefined,
  );
  const [killStrategyItems, setKillStrategyItems] = createSignal<Scheme["killStrategyItems"]>([]);
  const [mentionText, setMentionText] = createSignal<Scheme["mentionText"] | undefined>(undefined);
  const [mentionTextItems, setMentionTextItems] = createSignal<Scheme["mentionTextItems"]>([]);
  const [imageChoicesCount, setImageChoicesCount] = createSignal<Scheme["imageChoicesCount"] | undefined>(undefined);
  const [imageChoicesCountItems, setImageChoicesCountItems] = createSignal<Scheme["imageChoicesCountItems"]>([]);
  const [cleanupMessage, setCleanupMessages] = createSignal<Scheme["cleanupMessages"]>([]);
  const [delayUnbanSecs, setDelayUnbanSecs] = createSignal<Scheme["delayUnbanSecs"] | undefined>(undefined);

  const customizeQuery = useQuery(() => ({
    queryKey: ["customize"],
    queryFn: getCustomize,
  }));

  const handleTypeChange = (item: SelectItem) => setType(item.value);
  const handleKillStrategyChange = (item: SelectItem) => setKillStrategy(item.value);
  const handleFallbackKillStrategyChange = (item: SelectItem) => setFallbackKillStrategy(item.value);
  const handleMentionTextChange = (item: SelectItem) => setMentionText(item.value);
  const handleImageChoicesCountChange = (item: SelectItem) => setImageChoicesCount(Number(item.value));

  const handleCleanupMessagesChange = (kind: ServerData.MessageKind, checked: boolean) => {
    setCleanupMessages((prev) => {
      if (checked) {
        return [...prev, kind];
      } else {
        return prev.filter((item) => item !== kind);
      }
    });
  };

  createEffect(() => {
    if (customizeQuery.data?.success) {
      const scheme = customizeQuery.data.payload.scheme;
      setType(scheme.type);
      setTypeItems(scheme.typeItems);
      setTimeout(scheme.timeout);
      setKillStrategy(scheme.killStrategy);
      setFallbackKillStrategy(scheme.fallbackKillStrategy);
      setKillStrategyItems(scheme.killStrategyItems);
      setMentionText(scheme.mentionText);
      setMentionTextItems(scheme.mentionTextItems);
      setImageChoicesCount(scheme.imageChoicesCount);
      setImageChoicesCountItems(scheme.imageChoicesCountItems);
      setCleanupMessages(scheme.cleanupMessages);
      setDelayUnbanSecs(scheme.delayUnbanSecs);
    }
  });

  onMount(() => {
    setTitle("全局调整");
    setPage("customize");
  });

  return (
    <PageBase>
      <div class="flex flex-col gap-[1.5rem]">
        <FieldGroup title="验证配置" icon="fluent-color:lock-shield-16">
          <SelectField
            lable="验证方式"
            placeholder="选择一个验证方式"
            items={typeItems()}
            onChange={handleTypeChange}
            default={type()}
          />
          <SelectField
            lable="击杀策略（验证错误）"
            placeholder="选择一个击杀方法"
            items={killStrategyItems()}
            onChange={handleFallbackKillStrategyChange}
            default={killStrategy()}
          />
          <SelectField
            lable="击杀策略（验证超时）"
            placeholder="选择一个击杀方法"
            items={killStrategyItems()}
            onChange={handleKillStrategyChange}
            default={fallbackKillStrategy()}
          />
        </FieldGroup>
        <FieldGroup title="时间配置" icon="twemoji:hourglass-not-done">
          <InputField
            lable="超时时长"
            placeholder="输入数值（秒）"
            type="number"
            value={timeout()}
            onChange={setTimeout}
          />
          <InputField
            lable="解封延时"
            placeholder="输入数值（秒）"
            type="number"
            value={delayUnbanSecs()}
            onChange={setDelayUnbanSecs}
          />
        </FieldGroup>
        <FieldGroup title="显示配置" icon="streamline-plump-color:eye-optic">
          <SelectField
            lable="提及文本"
            placeholder="选择提及文本"
            items={mentionTextItems()}
            onChange={handleMentionTextChange}
            default={mentionText()}
          />
          <SelectField
            lable="答案个数（图片验证）"
            placeholder="选择答案个数"
            items={imageChoicesCountItems()}
            onChange={handleImageChoicesCountChange}
            default={imageChoicesCount()?.toString()}
          />
        </FieldGroup>
        <FieldGroup title="其它" icon="twemoji:hammer-and-wrench">
          <FieldRoot lable="消息清理">
            <div class="flex gap-[1rem]">
              <Checkbox
                label="加入群组"
                default={cleanupMessage().includes("joined")}
                onChange={(checked) => handleCleanupMessagesChange("joined", checked)}
              />
              <Checkbox
                label="退出群组"
                default={cleanupMessage().includes("left")}
                onChange={(checked) => handleCleanupMessagesChange("left", checked)}
              />
            </div>
          </FieldRoot>
        </FieldGroup>
      </div>
    </PageBase>
  );
};

const FieldGroup = (props: { title: string; icon: string; children: JSX.Element }) => {
  return (
    <div class="pt-[0.5rem] pb-[1rem] bg-white border-l-4 border-blue-400 hover:border-blue-500 rounded shadow hover:shadow-lg hover:translate-x-[1px] hover:translate-y-[-1px] transition-all">
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

const SelectField = (
  props: {
    lable: string;
    placeholder: string;
    items: SelectItem[];
    default?: string;
    onChange?: (item: SelectItem) => void;
  },
) => {
  return (
    <FieldRoot lable={props.lable}>
      <Select placeholder={props.placeholder} items={props.items} onChange={props.onChange} default={props.default} />
    </FieldRoot>
  );
};

const InputField = (
  props: {
    lable: string;
    placeholder: string;
    type?: JSX.InputHTMLAttributes<HTMLInputElement>["type"];
    value?: string | number;
    onChange?: (value: string) => void;
  },
) => {
  return (
    <FieldRoot lable={props.lable}>
      <input
        placeholder={props.placeholder}
        type={props.type || "text"}
        class="w-full h-[2.5rem] px-[1rem] input-edge"
        value={props.value}
        onChange={(e) => props.onChange?.(e.currentTarget.value)}
      />
    </FieldRoot>
  );
};

const Checkbox = (props: { label: string; default?: boolean; onChange?: (checked: boolean) => void }) => {
  const [checked, setChecked] = createSignal<boolean | undefined>(undefined);
  const toggleChecked = () => {
    const newState = !checked();
    setChecked(newState);
    props.onChange?.(newState);
  };

  createEffect(() => {
    if (checked() === undefined && props.default) {
      setChecked(props.default);
    }
  });

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

const FieldRoot = (props: { lable: string; children: JSX.Element }) => {
  return (
    <div class="flex items-center">
      <span class="w-[16rem]">{props.lable}</span>
      <div class="flex-1">
        {props.children}
      </div>
    </div>
  );
};
