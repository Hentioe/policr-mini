import React, { useEffect } from "react";
import { useSelector } from "react-redux";
import useSWR from "swr";
import tw, { styled } from "twin.macro";
import { useDispatch } from "react-redux";
import { useHistory, useLocation } from "react-router-dom";
import MoonLoader from "react-spinners/MoonLoader";

import { getIdFromLocation } from "../helper";
import { receiveChats, selectChat } from "../slices/chats";

const ChatItemBox = styled.div(({ selected = false }) => [
  tw`p-3 flex flex-col`, // 布局
  tw`border border-solid border-0 border-b border-gray-200`, // 边框
  tw`hover:bg-gray-200 cursor-pointer`, // 交互
  selected && tw`text-blue-500`,
]);

const ChatItem = ({ chat: chat, selected: selected, onSelect: onSelect }) => {
  return (
    <ChatItemBox selected={selected} onClick={onSelect}>
      <div tw="flex justify-center lg:justify-start">
        <img
          tw="w-12 h-12 lg:w-8 lg:h-8"
          src={`/admin/api/chats/${chat.id}/photo`}
        />
        <span tw="self-center hidden lg:inline ml-2 truncate">
          {chat.title}
        </span>
      </div>
    </ChatItemBox>
  );
};

const Loading = () => {
  return (
    <div tw="flex justify-center my-6">
      <MoonLoader size={25} color="#47A8D8" />
    </div>
  );
};

const endpoint = "/admin/api/chats";
const defaultMenu = "custom";

export default () => {
  const dispatch = useDispatch();
  const history = useHistory();
  const location = useLocation();

  const { data, error } = useSWR(endpoint);
  const chatsState = useSelector((state) => state.chats);

  const handleSelect = (id) =>
    history.push(`/admin/chats/${id}/${defaultMenu}`);

  useEffect(() => {
    if (data) dispatch(receiveChats(data.chats));
  }, [data]);

  useEffect(() => {
    if (chatsState.selected == null && data) {
      history.push(`/admin/chats/${data.chats[0].id}/${defaultMenu}`);
    }
  }, [chatsState]);

  // 根据 URL 的变化修改选中的群组
  useEffect(() => {
    const chatId = getIdFromLocation(location);
    if (chatId) dispatch(selectChat(chatId));
  }, [location]);

  if (error) return <div>载入出错</div>;

  return (
    <div>
      <div tw="flex flex-col bg-gray-100 rounded-lg shadow mx-4 my-2">
        <div tw="p-3 border border-solid border-0 border-b border-gray-200">
          <span tw="hidden lg:inline text-xl text-black">您的群组</span>
          <span tw="lg:hidden block text-center text-xl text-black">群组</span>
        </div>
        {chatsState.isLoaded ? (
          <>
            <div>
              {chatsState.list.map((chat) => (
                <ChatItem
                  key={chat.id}
                  chat={chat}
                  selected={chatsState.selected == chat.id}
                  onSelect={() => handleSelect(chat.id)}
                />
              ))}
            </div>
            <div tw="p-3">
              {data.ending ? (
                <>
                  <span tw="hidden lg:inline text-lg text-gray-600">
                    没有更多了
                  </span>
                  <span tw="block lg:hidden text-center text-gray-600">
                    没有了
                  </span>
                </>
              ) : (
                <a tw="text-blue-500 no-underline" href="#">
                  显示更多
                </a>
              )}
            </div>
          </>
        ) : (
          <Loading />
        )}
      </div>
    </div>
  );
};
