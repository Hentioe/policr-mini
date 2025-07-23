import { useQuery } from "@tanstack/solid-query";
import { createEffect, createSignal, onMount } from "solid-js";
import { getCustomize, updateDefaultScheme } from "../../api";
import { ActionButton } from "../../components";
import { PageBase } from "../../layouts";
import { setPage } from "../../state/global";
import { setTitle } from "../../state/meta";
import { toaster } from "../../utils";
import Checkbox from "./Checkbox";
import FieldGroup from "./FieldGroup";
import FieldRoot from "./FieldRoot";
import InputField from "./InputField";
import SelectField from "./SelectField";

type Scheme = ServerData.Scheme;

export default () => {
  const customizeQuery = useQuery(() => ({
    queryKey: ["customize"],
    queryFn: getCustomize,
    // 禁止自动刷新
    refetchOnWindowFocus: false,
    refetchIntervalInBackground: false,
  }));

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
  const [prevScheme, setPrevScheme] = createSignal<Scheme | undefined>(undefined);
  const [isChanged, setIsChanged] = createSignal(false);
  const [isSaving, setIsSaving] = createSignal(false);

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
      setPrevScheme(scheme);
    }
  });

  createEffect(() => {
    const prev = prevScheme();
    if (prev) {
      const isChanged = prev.type !== type()
        || prev.timeout !== timeout()
        || prev.killStrategy !== killStrategy()
        || prev.fallbackKillStrategy !== fallbackKillStrategy()
        || prev.mentionText !== mentionText()
        || prev.imageChoicesCount !== imageChoicesCount()
        || prev.cleanupMessages.join(",") !== cleanupMessage().join(",")
        || prev.delayUnbanSecs !== delayUnbanSecs()
        || prev.timeout !== timeout();

      setIsChanged(isChanged);
    }
  });

  const handleSave = async () => {
    setIsSaving(true);
    const resp = await updateDefaultScheme({
      type: type(),
      timeout: timeout(),
      killStrategy: killStrategy(),
      fallbackKillStrategy: fallbackKillStrategy(),
      mentionText: mentionText(),
      imageChoicesCount: imageChoicesCount(),
      cleanupMessages: cleanupMessage(),
      delayUnbanSecs: delayUnbanSecs(),
    });

    setIsSaving(false);
    if (resp.success) {
      setPrevScheme(resp.payload);
      toaster.success({
        title: "保存成功",
        description: "全局配置已更新",
        duration: 2500,
      });
    }
  };

  onMount(() => {
    setTitle("全局调整");
    setPage("customize");
  });

  return (
    <PageBase>
      <div class="flex flex-col gap-[1.5rem]">
        <FieldGroup title="验证配置" icon="fluent-color:lock-shield-16">
          <SelectField
            label="验证方式"
            placeholder="选择一个验证方式"
            items={typeItems()}
            onChange={handleTypeChange}
            default={type()}
          />
          <SelectField
            label="击杀策略（验证错误）"
            placeholder="选择一个击杀方法"
            items={killStrategyItems()}
            onChange={handleFallbackKillStrategyChange}
            default={killStrategy()}
          />
          <SelectField
            label="击杀策略（验证超时）"
            placeholder="选择一个击杀方法"
            items={killStrategyItems()}
            onChange={handleKillStrategyChange}
            default={fallbackKillStrategy()}
          />
        </FieldGroup>
        <FieldGroup title="时间配置" icon="twemoji:hourglass-not-done">
          <InputField
            label="超时时长"
            placeholder="输入数值（秒）"
            type="number"
            value={timeout()}
            onInput={(v) => setTimeout(Number(v))}
          />
          <InputField
            label="解封延时"
            placeholder="输入数值（秒）"
            type="number"
            value={delayUnbanSecs()}
            onInput={(v) => setDelayUnbanSecs(Number(v))}
          />
        </FieldGroup>
        <FieldGroup title="显示配置" icon="streamline-plump-color:eye-optic">
          <SelectField
            label="提及文本"
            placeholder="选择提及文本"
            items={mentionTextItems()}
            onChange={handleMentionTextChange}
            default={mentionText()}
          />
          <SelectField
            label="答案个数（图片验证）"
            placeholder="选择答案个数"
            items={imageChoicesCountItems()}
            onChange={handleImageChoicesCountChange}
            default={imageChoicesCount()?.toString()}
          />
        </FieldGroup>
        <FieldGroup title="其它" icon="twemoji:hammer-and-wrench">
          <FieldRoot label="消息清理">
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
      <div class="mt-[1rem]">
        <ActionButton
          onClick={handleSave}
          loading={isSaving()}
          disabled={!isChanged()}
          variant="info"
          size="lg"
          fullWidth
        >
          保存更改
        </ActionButton>
      </div>
    </PageBase>
  );
};
