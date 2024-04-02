import React, { useCallback, useState, useEffect } from "react";
import { useSelector, useDispatch } from "react-redux";
import { useLocation, Link as RouteLink } from "react-router-dom";
import tw, { styled } from "twin.macro";
import MoonLoader from "react-spinners/MoonLoader";
import Switch from "react-switch";

import {
  camelizeJson,
  toastErrors,
  updateInNewArray,
  isSysLink,
} from "../helper";
import { loadSelected, receiveChats } from "../slices/chats";

const NavItemLink = styled(RouteLink)`
  ${tw`py-3 px-6 no-underline text-black tracking-wider`}
  ${tw`hover:bg-blue-100 hover:text-blue-500`}
  ${tw`border-0 border-l-2 border-r-2 border-solid border-transparent`}
  ${({ selected = false }) => selected && tw`text-blue-500 border-current`}
  ${({ $ended = false }) => $ended && tw`rounded-b-lg`}
  border-right-color: transparent;
`;

const NavItem = ({ title, href, selected, ended }) => {
  return (
    <NavItemLink to={href} selected={selected} $ended={ended}>
      <span tw="xl:text-lg">{title}</span>
    </NavItemLink>
  );
};

function isSelect(page, path) {
  const re = new RegExp(`^/admin/chats/-\\d+/${page}`);

  return re.test(path);
}

const Loading = () => {
  return (
    <div tw="flex justify-center my-6">
      <MoonLoader size={25} color="#47A8D8" />
    </div>
  );
};

const MenuBox = ({
  visibility = true,
  isLoaded = true,
  title,
  miniTitle,
  children,
}) => {
  if (!visibility) return null;

  return (
    <div tw="flex flex-col bg-gray-100 rounded-lg mx-4 my-2 shadow">
      <div tw="p-3 border border-solid border-0 border-b border-gray-200">
        <span tw="hidden lg:inline text-xl text-black">{title}</span>
        <span tw="lg:hidden block text-center text-xl text-black">
          {miniTitle}
        </span>
      </div>
      {isLoaded ? <>{children}</> : <Loading />}
    </div>
  );
};

const ArrowDownIcon = () => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    tw="h-3"
    viewBox="0 0 20 20"
    fill="currentColor"
  >
    <path
      fillRule="evenodd"
      d="M14.707 12.293a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 111.414-1.414L9 14.586V3a1 1 0 012 0v11.586l2.293-2.293a1 1 0 011.414 0z"
      clipRule="evenodd"
    />
  </svg>
);

const ArrowUpIcon = () => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    tw="h-3"
    viewBox="0 0 20 20"
    fill="currentColor"
  >
    <path
      fillRule="evenodd"
      d="M5.293 7.707a1 1 0 010-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 01-1.414 1.414L11 5.414V17a1 1 0 11-2 0V5.414L6.707 7.707a1 1 0 01-1.414 0z"
      clipRule="evenodd"
    />
  </svg>
);

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
  const [isOnOwnerMenu, setIsOnOwnerMenu] = useState(
    isSysLink({ path: location.pathname })
  );

  const [passedRate, setPassedRate] = useState(["--", 0]);
  const [notPassedRate, setNotPassedRate] = useState(["--", 0]);

  const handleTakeOverChange = useCallback(
    (checked) => {
      setIsTakeOver(checked);
      changeTakeover({
        chatId: chatsState.selected,
        isTakeOver: checked,
      }).then((result) => {
        if (result.errors) {
          toastErrors(result.errors);
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

  useEffect(() => {
    setIsOnOwnerMenu(isSysLink({ path: location.pathname }));
  }, [location]);

  return (
    <nav>
      <MenuBox
        isLoaded={chatsState.isLoaded}
        title="管理员菜单"
        miniTitle="菜单"
      >
        <div tw="px-6 py-3 text-sm border-0 border-l-2 border-r-2 border-solid border-transparent flex items-center justify-between">
          <div tw="font-medium text-gray-600 ">
            {__GLOBAL__.userInfo.fullname}
          </div>
          <a
            tw="underline text-gray-500 text-xs flex items-center"
            href="/admin/logout"
          >
            <span>登出</span>&nbsp;
            <svg
              tw="w-3 h-3"
              xmlns="http://www.w3.org/2000/svg"
              className="h-6 w-6"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"
              />
            </svg>
          </a>
        </div>
        <NavItem
          title="方案定制"
          href={`/admin/chats/${chatsState.selected}/scheme`}
          selected={isSelect("scheme", location.pathname)}
        />
        {/* <NavItem
          title="消息模板"
          href={`/admin/chats/${chatsState.selected}/template`}
          selected={isSelect("template", location.pathname)}
        /> */}
        <NavItem
          title="验证记录"
          href={`/admin/chats/${chatsState.selected}/verifications`}
          selected={isSelect("verifications", location.pathname)}
        />
        <NavItem
          title="操作记录"
          href={`/admin/chats/${chatsState.selected}/operations`}
          selected={isSelect("operations", location.pathname)}
        />
        <NavItem
          title="管理员权限"
          href={`/admin/chats/${chatsState.selected}/permissions`}
          selected={isSelect("permissions", location.pathname)}
        />
        {/* <NavItem
          title="机器人属性"
          href={`/admin/chats/${chatsState.selected}/properties`}
          selected={isSelect("properties", location.pathname)}
        /> */}
        <NavItem
          title="自定义"
          href={`/admin/chats/${chatsState.selected}/custom`}
          selected={isSelect("custom", location.pathname)}
        />
        {chatsState.loadedSelected && !isOnOwnerMenu ? (
          <>
            {/*因为菜单链接有一个宽度为 2px 的左右边框，此处需要增加对应宽度的外边距以保持对齐。*/}
            <div tw="pt-3 px-6" style={{ marginLeft: 2, marginRight: 2 }}>
              <span tw="xl:text-lg text-gray-600">数据统计</span>
              <div tw="flex items-center justify-between">
                <p tw="text-gray-500/80 text-sm">私聊 <span>/console</span> 命令，从全新的控制台页面查看完整统计。</p>
              </div>
            </div>
            <div
              tw="py-3 px-6 text-lg text-gray-600 flex justify-between"
              style={{ marginLeft: 2, marginRight: 2 }}
            >
              <span>
                {chatsState.loadedSelected.isTakeOver ? "已接管" : "未接管"}
              </span>
              <Switch
                checked={isTakeOver}
                checkedIcon={false}
                uncheckedIcon={false}
                onChange={handleTakeOverChange}
              />
            </div>
          </>
        ) : !isOnOwnerMenu ? (
          <div tw="py-3 px-6 text-lg text-gray-600 flex justify-between">
            <span>检查中…</span>
          </div>
        ) : null}
      </MenuBox>

      <MenuBox
        visibility={__GLOBAL__.userInfo.isOwner}
        title="系统菜单"
        miniTitle="系统"
      >
        <NavItem
          title="批量管理"
          href="/admin/sys/managements"
          selected={isSysLink({ path: location.pathname, page: "managements" })}
        />
        <NavItem
          title="全局属性"
          href="/admin/sys/profile"
          selected={isSysLink({ path: location.pathname, page: "profile" })}
        />
        <NavItem
          title="系统任务"
          href="/admin/sys/tasks"
          selected={isSysLink({ path: location.pathname, page: "tasks" })}
        />
        <NavItem
          title="服务条款"
          href="/admin/sys/terms"
          selected={isSysLink({ path: location.pathname, page: "terms" })}
          ended={__GLOBAL__.botInfo.isThirdParty}
        />
        {/* <NavItem
          title="模拟终端"
          href="/admin/sys/terminal"
          selected={isSysLink({ path: location.pathname, page: "terminal" })}
        /> */}
        {!__GLOBAL__.botInfo.isThirdParty ? (
          <>
            <NavItem
              title="赞助记录"
              href="/admin/sys/sponsorship"
              selected={isSysLink({
                path: location.pathname,
                page: "sponsorship",
              })}
            />

            <NavItem
              title="第三方实例"
              href="/admin/sys/third_parties"
              selected={isSysLink({
                path: location.pathname,
                page: "third_parties",
              })}
              ended={true}
            />
          </>
        ) : undefined}
      </MenuBox>
    </nav>
  );
};
