import React from "react";
import useSWR from "swr";
import tw, { styled } from "twin.macro";

const ChatItemBox = styled.div(() => [
  tw`p-3 flex flex-col`, // 布局
  tw`border border-solid border-0 border-b border-gray-300`, // 边框
  tw`hover:bg-gray-200 cursor-pointer`, // 交互
]);

const ChatItem = ({ chat: chat }) => {
  return (
    <ChatItemBox>
      <div>
        <span tw="font-bold">{chat.title}</span>
      </div>
    </ChatItemBox>
  );
};

const fetcher = (url) => fetch(url).then((r) => r.json());

export default () => {
  const { data, error } = useSWR("/admin/api/chats", fetcher);

  if (error) return <div>载入出错</div>;
  if (!data) return <div>正在加载</div>;

  const chats = data.chats;

  return (
    <div>
      <div tw="bg-gray-100 rounded-lg mx-4 my-2">
        <div tw="p-3 border border-solid border-0 border-b border-gray-300">
          <span tw="text-lg font-bold">您的群组</span>
        </div>
        <div>
          {chats.map((chat) => (
            <ChatItem key={chat.id} chat={chat} />
          ))}
        </div>
        <div tw="p-3">
          <a tw="text-blue-500 no-underline" href="#">
            显示更多
          </a>
        </div>
      </div>
    </div>
  );
};
