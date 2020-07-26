import React from "react";
import useSWR from "swr";
import tw, { styled } from "twin.macro";

const ChatItemBox = styled.div(() => [
  tw`p-3 flex flex-col`, // 布局
  tw`border border-solid border-0 border-b border-gray-200`, // 边框
  tw`hover:bg-gray-200 cursor-pointer`, // 交互
]);

const ChatItem = ({ chat: chat }) => {
  return (
    <ChatItemBox>
      <div tw="flex justify-center lg:justify-start">
        <img tw="w-12 lg:w-6" src={`/admin/api/chats/${chat.id}/photo`} />
        <span tw="hidden lg:inline ml-2 font-bold truncate">{chat.title}</span>
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
        <div tw="p-3 border border-solid border-0 border-b border-gray-200">
          <span tw="hidden lg:inline text-xl font-bold">您的群组</span>
          <span tw="lg:hidden block text-center text-xl font-bold">群组</span>
        </div>
        <div>
          {chats.map((chat) => (
            <ChatItem key={chat.id} chat={chat} />
          ))}
        </div>
        <div tw="p-3">
          {data.ending ? (
            <>
              <span tw="hidden lg:inline text-gray-600">没有更多了</span>
              <span tw="block lg:hidden text-center text-gray-600">没有了</span>
            </>
          ) : (
            <a tw="text-blue-500 no-underline" href="#">
              显示更多
            </a>
          )}
        </div>
      </div>
    </div>
  );
};
