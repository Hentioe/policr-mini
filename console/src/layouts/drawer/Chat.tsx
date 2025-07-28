import classNames from "classnames";
import { For, JSX, Show } from "solid-js";
import Loading from "../../components/Loading";

const Item = (props: { current?: boolean; data: ServerData.Chat; onClick?: (chat: ServerData.Chat) => void }) => {
  const handleClick = (chat: ServerData.Chat) => {
    props.onClick?.(chat);
  };

  return (
    <div
      onClick={() => handleClick(props.data)}
      class={classNames([
        "max-w-full flex p-[0.5rem] text-zinc-600 bg-blue-50/40 hover:bg-zinc-300 cursor-pointer",
        {
          "bg-blue-400! text-zinc-50!": props.current,
        },
      ])}
    >
      <img src="/images/telegram-128x128.webp" width={128} height={128} class="w-[3rem]" />
      <div class="ml-[0.5rem] flex-1 min-w-0 flex flex-col justify-between">
        <p class="font-semibold truncate text-clip">{props.data.title}</p>
        <p class="text-sm tracking-wide line-clamp-1 truncate">{props.data.description}</p>
      </div>
    </div>
  );
};

const List = (
  props: { children: (chat: ServerData.Chat) => JSX.Element; isLoading?: boolean; each: ServerData.Chat[] },
) => {
  return (
    <div class="flex-1 flex flex-col *:not-last:border-b *:border-b-zinc-200 overflow-y-auto">
      <Show when={!props.isLoading} fallback={<MyLoading />}>
        <For each={props.each}>
          {(chat) => <>{props.children(chat)}</>}
        </For>
      </Show>
    </div>
  );
};

const MyLoading = () => {
  return (
    <div class="flex items-center justify-center h-full">
      <Loading size="xl" color="skyblue" />
    </div>
  );
};

export const Chat = {
  List,
  Item,
};
