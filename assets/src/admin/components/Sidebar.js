import React from "react";
import { useSelector } from "react-redux";
import { useLocation, Link as RouteLink } from "react-router-dom";
import tw, { styled } from "twin.macro";
import MoonLoader from "react-spinners/MoonLoader";

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

export default () => {
  const chatsState = useSelector((state) => state.chats);
  const { isLoaded, selected: currentChatId } = chatsState;
  const location = useLocation();

  return (
    <nav>
      <div tw="flex flex-col bg-gray-100 rounded-lg mx-4 my-2 shadow">
        <div tw="p-3 border border-solid border-0 border-b border-gray-200">
          <span tw="hidden lg:inline text-xl text-black">管理员菜单</span>
          <span tw="lg:hidden block text-center text-xl text-black">菜单</span>
        </div>
        {isLoaded ? (
          <>
            <NavItem
              title="数据统计"
              href={`/admin/chats/${currentChatId}/statistics`}
              selected={isSelect("statistics", location.pathname)}
            />
            <NavItem
              title="验证方案"
              href={`/admin/chats/${currentChatId}/scheme`}
              selected={isSelect("scheme", location.pathname)}
            />
            <NavItem
              title="验证提示"
              href={`/admin/chats/${currentChatId}/template`}
              selected={isSelect("template", location.pathname)}
            />
            <NavItem
              title="验证日志"
              href={`/admin/chats/${currentChatId}/logs`}
              selected={isSelect("logs", location.pathname)}
            />
            <NavItem
              title="封禁记录"
              href={`/admin/chats/${currentChatId}/banned`}
              selected={isSelect("banned", location.pathname)}
            />
            <NavItem
              title="管理员权限"
              href={`/admin/chats/${currentChatId}/permissions`}
              selected={isSelect("permissions", location.pathname)}
            />
            <NavItem
              title="机器人属性"
              href={`/admin/chats/${currentChatId}/properties`}
              selected={isSelect("properties", location.pathname)}
            />
            <NavItem
              title="自定义"
              href={`/admin/chats/${currentChatId}/custom`}
              selected={isSelect("custom", location.pathname)}
              ending="true"
            />
          </>
        ) : (
          <Loading />
        )}
      </div>
    </nav>
  );
};
