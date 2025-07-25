import { Accordion } from "@ark-ui/solid/accordion";
import { Icon } from "@iconify-icon/solid";
import { createMemo, For, Index, JSX, Match, Show, Switch } from "solid-js";
import { ActionButton } from "../../components";

type ItemVlue = ServerData.CustomItem;

const Root = (props: { items: ItemVlue[]; children: (item: ItemVlue) => JSX.Element }) => {
  const defaultValue = createMemo(() => props.items.length > 0 ? props.items.map(item => item.id.toString()) : []);

  return (
    <Switch>
      <Match when={props.items.length > 0}>
        <Accordion.Root multiple collapsible lazyMount defaultValue={defaultValue()}>
          <Index each={props.items}>
            {(item) => <>{props.children(item())}</>}
          </Index>
        </Accordion.Root>
      </Match>
      <Match when={true}>
        <p>您还没有添加任何自定义验证。</p>
      </Match>
    </Switch>
  );
};

const Item = (props: { item: ItemVlue }) => {
  return (
    <Accordion.Item value={props.item.id.toString()}>
      <Accordion.ItemTrigger>
        <p class="line-clamp-1 truncate">
          {props.item.title}
        </p>
        <Accordion.ItemIndicator>
          <Icon icon="mingcute:down-line" />
        </Accordion.ItemIndicator>
      </Accordion.ItemTrigger>
      <Accordion.ItemContent>
        <Show when={props.item.attachment}>
          <Attachment value={props.item.attachment!} />
        </Show>
        <div class="flex flex-wrap gap-x-[1rem] gap-y-[0.5rem] py-[0.5rem]">
          <For each={props.item.answers}>
            {(answer) => (
              <>
                <Answer
                  text={answer.text}
                  correct={answer.correct}
                />
              </>
            )}
          </For>
          <Opes />
        </div>
      </Accordion.ItemContent>
    </Accordion.Item>
  );
};

const Attachment = (props: { value: string }) => {
  const type = () => {
    if (props.value.startsWith("photo/")) {
      return "图片";
    } else if (props.value.startsWith("video/")) {
      return "视频";
    } else if (props.value.startsWith("audio/")) {
      return "音频";
    } else if (props.value.startsWith("document/")) {
      return "文档";
    }
    return "未知类型附件";
  };

  return (
    <div class="h-[3rem] my-[0.5rem] bg-zinc-300 text-white rounded flex items-center justify-center">
      <p>{type()}</p>
    </div>
  );
};

const Answer = (props: { correct: boolean; text: string }) => {
  return (
    <div class="flex items-center gap-[0.5rem]">
      <Icon icon={props.correct ? "flat-color-icons:ok" : "noto-v1:cross-mark"} />
      <span>{props.text}</span>
    </div>
  );
};

const Opes = () => {
  return (
    <div class="w-full flex justify-between">
      <ActionButton variant="info" icon="mdi:eye" outline>
        预览
      </ActionButton>
      <ActionButton variant="info" icon="uil:edit">
        编辑
      </ActionButton>
      <ActionButton variant="danger" icon="lets-icons:del-alt-fill">
        删除
      </ActionButton>
    </div>
  );
};

export default {
  Root,
  Item,
};
