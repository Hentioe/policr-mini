import React from "react";
import tw, { styled } from "twin.macro";

const Link = styled.a.attrs({})`
  ${tw`no-underline`}
`;

const MenuItem = styled(Link).attrs({})`
  ${tw`md:inline-flex md:w-auto w-full px-5 py-2 rounded text-gray-600 items-center justify-center`}
`;

const BetaMarkup = styled.span.attrs({})`
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
        <span tw="text-xl font-bold text-blue-500 tracking-wide uppercase">
          policr mini
        </span>
        <BetaMarkup>beta</BetaMarkup>
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
        tw="hidden w-full md:inline-flex md:flex-grow md:w-auto"
        className="top-navbar"
        id="navigation"
      >
        <div tw="md:inline-flex md:ml-auto md:flex-row md:w-auto w-full md:items-center items-start flex flex-col md:h-auto">
          <MenuItem href="/">
            <span>首页</span>
          </MenuItem>
          <MenuItem href="#">
            <span>后台</span>
          </MenuItem>
          <MenuItem target="_blank" href="https://mini.telestd.me/community">
            <span>社群</span>
          </MenuItem>
          <MenuItem href="#">
            <span>维基</span>
          </MenuItem>
          <MenuItem href="#">
            <span>关于</span>
          </MenuItem>
          <MenuItem href="#" tw="bg-yellow-400">
            <span>快速入门</span>
          </MenuItem>
        </div>
      </div>
    </nav>
  );
};
