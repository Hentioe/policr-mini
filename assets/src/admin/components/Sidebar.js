import React, { useCallback, useState, useEffect } from "react";
import { useSelector, useDispatch } from "react-redux";
import { useLocation, Link as RouteLink } from "react-router-dom";
import tw, { styled } from "twin.macro";
import MoonLoader from "react-spinners/MoonLoader";
import Switch from "react-switch";

import { camelizeJson, toastError, updateInNewArray } from "../helper";
import { loadSelected, receiveChats } from "../slices/chats";

const NavItemLink = styled(
  RouteLink
)(({ selected = false, ending: ending }) => [
  tw`py-3 px-6 no-underline text-black tracking-wider`,
  tw`hover:bg-blue-100 hover:text-blue-500`,
  selected && tw`text-blue-500`,
  ending && tw`rounded-b`,
]);

const NavItem = ({
  title: title,
  href: href,
  selected: selected,
  ending: ending,
}) => {
  return (
    <NavItemLink to={href} selected={selected} ending={ending}>
      <span tw="xl:text-lg">{title}</span>
    </NavItemLink>
  );
};

function isSelect(page, url) {
  const re = new RegExp(`^/admin/chats/-\\d+/${page}`);

  return re.test(url);
}

const Loading = () => {
  return (
    <div tw="flex justify-center my-6">
      <MoonLoader size={25} color="#47A8D8" />
    </div>
  );
};

const changeTakeover = async ({ chatId, isTakeOver }) => {
  const endpoint = `/admin/api/chats/${chatId}/takeover?value=${isTakeOver}`;
  return fetch(endpoint, {
    method: "PUT",
    headers: {
      "Content-Type": "application/json",
    },
  }).then((r) => camelizeJson(r));
};

export default () => {
  const location = useLocation();
  const dispatch = useDispatch();

  const chatsState = useSelector((state) => state.chats);

  const [isTakeOver, setIsTakeOver] = useState(false);

  const handleTakeOverChange = useCallback(
    (checked) => {
      setIsTakeOver(checked);
      changeTakeover({
        chatId: chatsState.selected,
        isTakeOver: checked,
      }).then((result) => {
        if (result.errors) {
          toastError("接管状态修改接失败。");
          setIsTakeOver(!checked);
        } else {
          // 更新 chats 状态中的 `loadedSelected` 和 `list` 数据。
          if (result.chat.id == chatsState.selected) {
            dispatch(loadSelected(result.chat));
          }

          const dirtyIndex = chatsState.list.findIndex(
            (c) => c.id === result.chat.id
          );
          if (dirtyIndex > -1) {
            const newList = updateInNewArray(
              chatsState.list,
              result.chat,
              dirtyIndex
            );
            dispatch(receiveChats(newList));
          }
        }
      });
    },
    [chatsState]
  );

  useEffect(() => {
    if (chatsState.loadedSelected)
      setIsTakeOver(chatsState.loadedSelected.isTakeOver);
  }, [chatsState]);

  return (
    <nav>
      <div tw="flex flex-col bg-gray-100 rounded-lg mx-4 my-2 shadow">
        <div tw="p-3 border border-solid border-0 border-b border-gray-200">
          <span tw="hidden lg:inline text-xl text-black">管理员菜单</span>
          <span tw="lg:hidden block text-center text-xl text-black">菜单</span>
        </div>
        {chatsState.isLoaded ? (
          <>
            <NavItem
              title="数据统计"
              href={`/admin/chats/${chatsState.selected}/statistics`}
              selected={isSelect("statistics", location.pathname)}
            />
            <NavItem
              title="验证方案"
              href={`/admin/chats/${chatsState.selected}/scheme`}
              selected={isSelect("scheme", location.pathname)}
            />
            <NavItem
              title="验证提示"
              href={`/admin/chats/${chatsState.selected}/template`}
              selected={isSelect("template", location.pathname)}
            />
            <NavItem
              title="验证日志"
              href={`/admin/chats/${chatsState.selected}/logs`}
              selected={isSelect("logs", location.pathname)}
            />
            <NavItem
              title="封禁记录"
              href={`/admin/chats/${chatsState.selected}/banned`}
              selected={isSelect("banned", location.pathname)}
            />
            <NavItem
              title="管理员权限"
              href={`/admin/chats/${chatsState.selected}/permissions`}
              selected={isSelect("permissions", location.pathname)}
            />
            <NavItem
              title="机器人属性"
              href={`/admin/chats/${chatsState.selected}/properties`}
              selected={isSelect("properties", location.pathname)}
            />
            <NavItem
              title="自定义"
              href={`/admin/chats/${chatsState.selected}/custom`}
              selected={isSelect("custom", location.pathname)}
            />
            <div tw="py-3 px-6 text-lg text-gray-600 flex justify-between">
              {chatsState.loadedSelected ? (
                <>
                  <span>
                    {chatsState.loadedSelected.isTakeOver ? "已接管" : "未接管"}
                  </span>
                  <Switch
                    checked={isTakeOver}
                    checkedIcon={false}
                    uncheckedIcon={false}
                    onChange={handleTakeOverChange}
                  />
                </>
              ) : (
                <span>检查中…</span>
              )}
            </div>
          </>
        ) : (
          <Loading />
        )}
      </div>
    </nav>
  );
};
