import { destructure } from "@solid-primitives/destructure";
import { useQuery } from "@tanstack/solid-query";
import classNames from "classnames";
import { createEffect, For } from "solid-js";
import { getChats, getMe } from "../../api";
import { globalState } from "../../state";
import { setCurrentChat, setEmptyChatList, toggleDrawer } from "../../state/global";
import { Chat } from "./Chat";
import User from "./User";

export default () => {
  const { drawerIsOpen, currentChatId } = destructure(globalState);

  const meQuery = useQuery(() => ({
    queryKey: ["me"],
    queryFn: getMe,
  }));

  const chatsQuery = useQuery(() => ({
    queryKey: ["chats"],
    queryFn: getChats,
  }));

  const handleChatChange = (chat: ServerData.Chat) => {
    setCurrentChat(chat);
    toggleDrawer();
  };

  createEffect(() => {
    if (chatsQuery.data?.success && currentChatId() === null) {
      if (chatsQuery.data.payload.length > 0) {
        const currentChat = chatsQuery.data.payload[0];
        setCurrentChat(currentChat);
      } else {
        setEmptyChatList(true);
      }
    }
  });

  return (
    <nav
      id="drawer"
      class={classNames([
        "flex flex-col",
        {
          "open": drawerIsOpen(),
          "close": !drawerIsOpen(),
        },
      ])}
    >
      {/* 用户信息 */}
      <User user={meQuery.data?.success && meQuery.data?.payload} />
      {/* 群列表 */}
      <Chat.List>
        <For each={chatsQuery.data?.success ? chatsQuery.data.payload : []}>
          {(chat) => (
            <Chat.Item
              chat={chat}
              current={currentChatId() === chat.id}
              onClick={handleChatChange}
            />
          )}
        </For>
      </Chat.List>
    </nav>
  );
};
