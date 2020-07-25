import React from "react";
import tw, { styled } from "twin.macro";

const NavItemLink = styled.a(({ selected = false }) => [
  tw`py-3 px-6 no-underline rounded-full text-black tracking-wider hover:bg-blue-100 hover:text-blue-500`,
  selected && tw`text-blue-500`,
]);

const NavItem = ({ title: title, href: href, selected: selected }) => {
  return (
    <NavItemLink href={href} selected={selected}>
      <span tw="text-lg xl:text-xl font-bold">{title}</span>
    </NavItemLink>
  );
};

export default () => {
  return (
    <nav tw="flex flex-col">
      <NavItem title="数据统计" href="#" selected />
      <NavItem title="验证方案" href="#" />
      <NavItem title="验证提示" href="#" />
      <NavItem title="自定义" href="#" />
      <NavItem title="验证日志" href="#" />
      <NavItem title="封禁记录" href="#" />
      <NavItem title="管理员权限" href="#" />
      <NavItem title="机器人属性" href="#" />
    </nav>
  );
};
