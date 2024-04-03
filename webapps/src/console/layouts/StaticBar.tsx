import { useNavigate } from "@solidjs/router";
import { AiFillGithub } from "solid-icons/ai";
import { BiLogosTelegram } from "solid-icons/bi";
import { FaBrandsBloggerB } from "solid-icons/fa";
import { IoLanguageOutline } from "solid-icons/io";
import { IoCloseSharp } from "solid-icons/io";
import { createEffect, createSignal, For, JSXElement } from "solid-js";
import useSWR from "solid-swr";
import tw, { styled } from "twin.macro";
import { getter } from "../api";
import { Chat, useGlobalStore } from "../globalStore";

const Root = styled.div({
  ...tw`w-[4rem] lg:w-[5rem] py-2 flex flex-col`,
});

type ActiveProp = {
  active?: boolean;
};

type HoveredProp = {
  hovered?: boolean;
};

type disableInteractiveProp = {
  disableInteractive?: boolean;
};

const ItemBoxRoot = styled.div(() => [
  tw`flex relative items-center justify-center px-1 lg:px-2 my-2`,
]);

const ItemBoxLeft = styled.div((ps: ActiveProp & HoveredProp) => [
  tw`absolute left-0`,
  ps.hovered && !ps.active ? tw`bg-blue-400/40 h-[1rem] lg:h-[2rem] w-[0.15rem] lg:w-[0.3rem]` : tw`bg-transparent`,
  ps.active && tw`bg-blue-400 w-[0.15rem] lg:w-[0.3rem] h-[0.25rem] lg:h-[0.5rem] rounded-r`,
]);

const ItemBox = (props: { children: JSXElement } & ActiveProp & disableInteractiveProp) => {
  const [hovered, setHovered] = createSignal(false);

  let rootEl: HTMLDivElement | undefined;

  const handleHoverSwitch = () => {
    if (!props.disableInteractive) {
      setHovered(!hovered());
    }
  };

  return (
    <ItemBoxRoot ref={rootEl} onMouseEnter={handleHoverSwitch} onMouseLeave={handleHoverSwitch}>
      <ItemBoxLeft active={props.active} hovered={hovered()} />
      {props.children}
    </ItemBoxRoot>
  );
};

const ChatBoxRoot = styled.div((ps: ActiveProp & disableInteractiveProp) => [
  tw`w-[2.5rem] lg:w-[3.5rem] h-[2.5rem] lg:h-[3.5rem] flex items-center justify-center rounded-xl`,
  ps.active ? tw`bg-white/40` : !ps.disableInteractive && tw`hover:bg-white/20`,
  !ps.disableInteractive && tw`cursor-pointer`,
]);

type IconSchemeProp = {
  scheme?: "github" | "blog" | "language" | "telegram";
};

const IconBox = styled(ChatBoxRoot)((ps: IconSchemeProp) => [
  tw`rounded-full bg-white/40 transition duration-300`,
  ps.scheme === "language" && tw`hover:bg-green-500 text-green-500 hover:text-white hover:rounded-2xl `,
  ps.scheme === "blog" && tw`hover:bg-amber-400 text-amber-400 hover:text-white hover:rounded-2xl `,
  ps.scheme === "github" && tw`hover:bg-black text-black hover:text-white hover:rounded-2xl `,
  ps.scheme === "telegram" && tw`hover:bg-sky-400 text-sky-400 hover:text-white hover:rounded-2xl `,
]);

function saveLastChatId(chatId: number) {
  localStorage.setItem("lastChatId", chatId.toString());
}

function lastChatId(): string | null {
  return localStorage.getItem("lastChatId");
}

// 页面初次载入时的 URL
const loadedUrlPath = window.location.pathname;

type ChatsRepo = {
  chats: Chat[];
};

export default () => {
  const navigate = useNavigate();
  const { store, draw, setCurrentChat } = useGlobalStore();
  const [chats, loadChats] = createSignal<Chat[]>([]);

  const { data } = useSWR<ChatsRepo>(() => "/admin/api/chats", { fetcher: getter });

  createEffect(() => {
    if (data.v != null) {
      // 构造 chats
      const chats = data.v.chats.map((c: Chat) => ({ id: c.id, title: c.title, description: c.description }));
      // 装载到全局 chats
      loadChats(chats);
      // 解析 loadedUrlPath 中的 chatId 和 pageId
      const chatId = loadedUrlPath.match(/\/console\/(-\d+)/)?.[1] || lastChatId();
      const pageId = loadedUrlPath.match(/\/console\/-\d+\/([^/]+)/)?.[1];
      // 查找 chatId 对应的 chat
      const chat = chats.find((c) => c.id.toString() === chatId);
      console.log(chat);
      if (chat != null) {
        // 如果 chat 存在，设置为当前群聊
        setCurrentChat(chat);

        if (pageId == null) {
          // 如果路径中不存在 pageId，主动导航到缺省页面
          // TODO: 需进一步判断 pageId 是否有效
          navigate(`/${chat.id}`);
        }
      } else {
        // 如果 chat 不存在，设置第一个 chat 为 currentChat
        if (chats.length > 0) {
          const c = chats[0];
          setCurrentChat(c);
          navigate(`/${c.id}`);
        } else {
          // TODO: 如果 chats 为空，显示警告消息
        }
      }
    }
  });

  const ChatBox = (props: { chat: Chat; children: JSXElement }) => {
    const handleSelect = () => {
      setCurrentChat(props.chat);
      navigate(`/${props.chat.id}`);
      // 保存访问的 chatId 到本地
      saveLastChatId(props.chat.id);
    };

    return (
      <ChatBoxRoot active={store.currentChat?.id === props.chat.id} onClick={handleSelect}>
        {props.children}
      </ChatBoxRoot>
    );
  };

  return (
    <Root>
      <div>
        <div tw="lg:hidden">
          <ItemBox disableInteractive>
            <IoCloseSharp size="2rem" tw="text-white rounded-full bg-white/20" onClick={[draw, undefined]} />
          </ItemBox>
        </div>
        <ItemBox disableInteractive>
          <ChatBoxRoot disableInteractive>
            <img title="Avatar" src="/console/photo" tw="rounded-full" />
          </ChatBoxRoot>
        </ItemBox>
      </div>
      <div tw="flex-1 overflow-y-auto" class="hidden-scrollbar">
        <For each={chats()}>
          {(c) => (
            <ItemBox active={store.currentChat?.id === c.id}>
              <ChatBox chat={c}>
                <img
                  title={c.title}
                  src={`/admin/api/chats/${c.id}/photo`}
                  tw="rounded-full w-[80%] h-[80%]"
                />
              </ChatBox>
            </ItemBox>
          )}
        </For>
      </div>
      <div>
        <ItemBox disableInteractive>
          <a rel="noopener" href="https://t.me/policr_changelog" target="_blank">
            <IconBox scheme="telegram">
              <BiLogosTelegram size="1.5rem" />
            </IconBox>
          </a>
        </ItemBox>
        <ItemBox disableInteractive>
          <a rel="noopener" href="https://blog.gramlabs.org/" target="_blank">
            <IconBox scheme="blog">
              <FaBrandsBloggerB size="1.5rem" />
            </IconBox>
          </a>
        </ItemBox>
        <ItemBox disableInteractive>
          <a rel="noopener" href="https://github.com/Hentioe/policr-mini" target="_blank">
            <IconBox scheme="github">
              <AiFillGithub size="1.5rem" />
            </IconBox>
          </a>
        </ItemBox>
        <ItemBox disableInteractive>
          <IconBox scheme="language">
            <IoLanguageOutline size="1.5rem" />
          </IconBox>
        </ItemBox>
      </div>
    </Root>
  );
};
