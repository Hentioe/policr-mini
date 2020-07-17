import React from "react";
import tw, { styled } from "twin.macro";

const Link = styled.a`
  ${tw`no-underline`}
`;

const MenuLink = styled(Link)`
  ${tw`md:inline-flex md:w-auto w-full py-2 rounded text-gray-600 items-center justify-center`}
`;

const MenuText = styled.span`
  ${tw`px-5`}
`;

const BetaMarkup = styled.span`
  font-size: 0.5rem;
  margin-bottom: 0.5rem;
  ${tw`text-yellow-500 font-semibold`}
`;

// 参考来源：https://tailwindcomponents.com/component/simple-responsive-navigation-bar-1
export default () => {
  return (
    <nav tw="flex items-center bg-white p-3 flex-wrap">
      {/* LOGO&主页链接 */}
      <Link href="/" tw="p-2 mr-4 inline-flex items-center">
        <span tw="text-lg md:text-xl font-bold text-blue-500 tracking-wide uppercase">
          policr mini
        </span>
        <BetaMarkup tw="self-end">beta</BetaMarkup>
      </Link>
      {/* 参考按钮实现：https://tailwindui.com/components/application-ui/navigation/navbars */}
      {/* 展开/隐藏菜单按钮 */}
      {/* <button
        tw="text-white inline-flex p-3 hover:bg-gray-900 rounded lg:hidden ml-auto hover:text-white outline-none"
        className="nav-toggler"
        data-target="#navigation"
      >
        <svg
          tw="block h-6 w-6"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth="2"
            d="M4 6h16M4 12h16M4 18h16"
          />
        </svg>
      </button> */}
      <div
        tw="w-full md:inline-flex md:flex-grow md:w-auto"
        className="top-navbar"
        id="navigation"
      >
        <div tw="md:inline-flex md:ml-auto md:flex-row md:w-auto w-full md:items-center items-start flex flex-col md:h-auto">
          <MenuLink href="/">
            <MenuText>首页</MenuText>
          </MenuLink>
          <MenuLink href="#">
            <MenuText>后台</MenuText>
          </MenuLink>
          <MenuLink target="_blank" href="https://mini.telestd.me/community">
            <MenuText>社群</MenuText>
          </MenuLink>
          <MenuLink href="#">
            <MenuText>维基</MenuText>
          </MenuLink>
          <MenuLink href="#">
            <MenuText>关于</MenuText>
          </MenuLink>
          <MenuLink href="#" tw="bg-yellow-400">
            <MenuText>快速入门</MenuText>
          </MenuLink>
        </div>
      </div>
    </nav>
  );
};
