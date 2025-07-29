import { Accordion } from "@ark-ui/solid/accordion";
import { Icon } from "@iconify-icon/solid";
import classNames from "classnames";
import { createMemo, For, Index, JSX, Match, Show, Switch } from "solid-js";
import Loading from "../../components/Loading";

type ItemVlue = ServerData.CustomItem;

const Root = (props: { items?: ItemVlue[] | false; children: (item: ItemVlue, i: number) => JSX.Element }) => {
  const defaultValue = createMemo(() => {
    if (props.items) {
      return props.items.length > 0 ? props.items.map(item => item.id.toString()) : [];
    }
  });

  return (
    <Switch>
      <Match when={!props.items}>
        <div class="mt-[1.5rem] flex justify-center">
          <Loading size="lg" color="skyblue" />
        </div>
      </Match>
      <Match when={(props.items as ItemVlue[]).length > 0}>
        <Accordion.Root multiple collapsible lazyMount defaultValue={defaultValue()}>
          <Index each={props.items}>
            {(item, i) => <>{props.children(item(), i)}</>}
          </Index>
        </Accordion.Root>
      </Match>
      <Match when={true}>
        <p class="mt-[1.5rem] text-zinc-600 text-center tracking-wide">您还没有添加任何自定义验证。</p>
      </Match>
    </Switch>
  );
};

const Item = (props: { data: ItemVlue; n: number; buttons: JSX.Element[] }) => {
  return (
    <Accordion.Item value={props.data.id.toString()}>
      <Accordion.ItemTrigger>
        <div class="flex items-center min-w-0">
          <span class="w-[1.5rem] h-[1.5rem] mr-[0.5rem] flex items-center justify-center bg-blue-400 text-white rounded-full">
            {props.n}
          </span>
          <p class="flex-1 line-clamp-1 truncate font-medium">
            {props.data.title}
          </p>
        </div>
        <Accordion.ItemIndicator>
          <Icon icon="mingcute:down-line" />
        </Accordion.ItemIndicator>
      </Accordion.ItemTrigger>
      <Accordion.ItemContent>
        <Show when={props.data.attachment}>
          <Attachment value={props.data.attachment!} />
        </Show>
        <div class="grid grid-cols-2 gap-[0.5rem] py-[0.5rem]">
          <For each={props.data.answers}>
            {(answer) => (
              <Answer
                text={answer.text}
                correct={answer.correct}
              />
            )}
          </For>
        </div>
        <div class="w-full flex justify-between">
          <Index each={props.buttons}>
            {(button) => <>{button()}</>}
          </Index>
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
    <div
      class={classNames([
        "flex items-center gap-[0.5rem] px-[0.5rem] py-[0.25rem] border rounded-lg",
        {
          "bg-green-100 border-green-400": props.correct,
          "bg-red-100 border-red-400": !props.correct,
        },
      ])}
    >
      <Switch>
        <Match when={props.correct}>
          <Icon icon="flat-color-icons:ok" />
        </Match>
        <Match when={!props.correct}>
          <Icon icon="healthicons:no-24px" class="text-red-400" />
        </Match>
      </Switch>
      <span class="line-clamp-1 break-all">{props.text}</span>
    </div>
  );
};

export default {
  Root,
  Item,
};
