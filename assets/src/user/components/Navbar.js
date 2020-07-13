import React from "react";
import tw, { styled } from "twin.macro";

const Link = styled.a.attrs({})`
  ${tw`no-underline`}
`;

const MenuItem = styled(Link).attrs({})`
  ${tw`lg:inline-flex lg:w-auto w-full px-3 py-2 rounded text-gray-600 items-center justify-center hover:bg-gray-700 hover:text-white`}
`;

// 参考来源：https://tailwindcomponents.com/component/simple-responsive-navigation-bar-1
export default () => {
  return (
    <nav tw="flex items-center bg-white p-3 flex-wrap">
      {/* LOGO&主页链接 */}
      <Link href="/" tw="p-2 mr-4 inline-flex items-center text-blue-500">
        <span tw="text-xl font-bold tracking-wide uppercase">policr mini</span>
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
        tw="hidden w-full lg:inline-flex lg:flex-grow lg:w-auto"
        className="top-navbar"
        id="navigation"
      >
        <div tw="lg:inline-flex lg:flex-row lg:ml-auto lg:w-auto w-full lg:items-center items-start  flex flex-col lg:h-auto">
          <MenuItem href="/">
            <span>首页</span>
          </MenuItem>
          <MenuItem href="#">
            <span>教程</span>
          </MenuItem>
          <MenuItem href="#">
            <span>社区</span>
          </MenuItem>
          <MenuItem href="#">
            <span>维基</span>
          </MenuItem>
          <MenuItem href="#">
            <span>关于</span>
          </MenuItem>
        </div>
      </div>
    </nav>
  );
};
