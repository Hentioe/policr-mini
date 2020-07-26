import React from "react";
import { useSelector } from "react-redux";
import { useLocation, Link as RouteLink } from "react-router-dom";
import tw, { styled } from "twin.macro";
import MoonLoader from "react-spinners/MoonLoader";

const NavItemLink = styled(
  RouteLink
)(({ selected = false, ending = false }) => [
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
      <span tw="xl:text-lg font-bold">{title}</span>
    </NavItemLink>
  );
};

function isSelect(page, url) {
  const re = new RegExp(`^/admin/chats/\\d+/${page}`);

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
  const { isLoaded } = useSelector((state) => state.chats);
  const location = useLocation();

  return (
    <nav>
      <div tw="flex flex-col bg-gray-100 rounded-lg mx-4 my-2 shadow">
        <div tw="p-3 border border-solid border-0 border-b border-gray-200">
          <span tw="hidden lg:inline text-xl font-bold">管理员菜单</span>
          <span tw="lg:hidden block text-center text-xl font-bold">菜单</span>
        </div>
        {isLoaded ? (
          <>
            <NavItem
              title="数据统计"
              href="#"
              selected={isSelect("statistics", location.pathname)}
            />
            <NavItem
              title="验证方案"
              href="#"
              selected={isSelect("scheme", location.pathname)}
            />
            <NavItem
              title="验证提示"
              href="#"
              selected={isSelect("template", location.pathname)}
            />
            <NavItem
              title="验证日志"
              href="#"
              selected={isSelect("logs", location.pathname)}
            />
            <NavItem
              title="封禁记录"
              href="#"
              selected={isSelect("banned", location.pathname)}
            />
            <NavItem
              title="管理员权限"
              href="#"
              selected={isSelect("permissions", location.pathname)}
            />
            <NavItem
              title="机器人属性"
              href="#"
              selected={isSelect("properties", location.pathname)}
            />
            <NavItem
              title="自定义"
              href="#"
              selected={isSelect("custom", location.pathname)}
              ending
            />
          </>
        ) : (
          <Loading />
        )}
      </div>
    </nav>
  );
};
