import classNames from "classnames";
import { JSX } from "solid-js";

const Item = (props: { current?: boolean; chat: ServerData.Chat; onClick?: (chat: ServerData.Chat) => void }) => {
  const handleClick = (chat: ServerData.Chat) => {
    props.onClick?.(chat);
  };

  return (
    <div
      onClick={() => handleClick(props.chat)}
      class={classNames([
        "max-w-full flex p-[0.5rem] text-zinc-600 bg-blue-50/40 hover:bg-zinc-300 cursor-pointer",
        {
          "bg-blue-400! text-zinc-50!": props.current,
        },
      ])}
    >
      <img src="/images/telegram-128x128.webp" width={128} height={128} class="w-[3rem]" />
      <div class="ml-[0.5rem] flex-1 min-w-0 flex flex-col justify-between">
        <p class="font-semibold truncate text-clip">{props.chat.title}</p>
        <p class="text-sm tracking-wide line-clamp-1 truncate">{props.chat.description}</p>
      </div>
    </div>
  );
};

const List = (props: { children: JSX.Element }) => {
  return (
    <div class="flex-1 flex flex-col *:not-last:border-b *:border-b-zinc-200 overflow-y-auto">
      {props.children}
    </div>
  );
};

export const Chat = {
  List,
  Item,
};
