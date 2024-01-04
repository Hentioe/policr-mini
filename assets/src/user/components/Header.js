import React from "react";
import tw, { styled } from "twin.macro";
import { useDispatch } from "react-redux";
import { Link as RouteLink } from "react-router-dom";

import { open as openModal } from "../slices/modal";
import Confirm from "./Confirm";

const Link = styled.a`
  ${tw`no-underline`}
`;

const MenuLink = styled.a`
  ${tw`no-underline md:inline-flex md:w-auto w-full py-2 rounded text-gray-600 items-center justify-center cursor-pointer`}
`;

const RouteMenuLink = styled(RouteLink)`
  ${tw`no-underline md:inline-flex md:w-auto w-full py-2 rounded text-gray-600 items-center justify-center cursor-pointer`}
`;

const MenuText = styled.span`
  ${tw`px-5`}
`;

const LogoMarkup = styled.span`
  font-size: 0.5rem;
  margin-bottom: 0.5rem;
  ${tw`text-orange-500 font-semibold`}
`;

const version = "beta";
const thirdParty = "T-party";

const buildPageContentMissingConfirm = ({ title }) => (
  <Confirm title={title}>
    <span tw="text-gray-600">
      由于此项目暂未完全实现，此页面内容有待填充。更多细节请参阅
      <a
        tw="text-blue-600"
        target="_blank"
        href="https://t.me/policr_changelog?boost"
      >
        更新频道
      </a>
      或在
      <a
        tw="text-blue-600"
        target="_blank"
        href="https://mini.gramlabs.org/community"
      >
        社群
      </a>
      寻求帮助。
    </span>
  </Confirm>
);

const GradientText = styled.span`
  -webkit-text-fill-color: transparent;
  background: -webkit-linear-gradient(-70deg, #00f9ff, #0081ff);
  -webkit-background-clip: text;
`;

const LogoContainer = styled.div`
  ${tw`text-lg md:text-xl font-bold text-blue-500 tracking-wide uppercase`}

  &:after {
    content: "${_GLOBAL.isThirdParty ? thirdParty : version}";
    color: #ff5733;
    font-size: 0.5rem;
    font-weight: 600;
    text-transform: none;
    transform: translateY(-0.25rem);
    display: inline-block;
    margin-left: 4px;
  }
`;

const GradientLogo = ({ children }) => {
  return (
    <LogoContainer>
      <GradientText>{children}</GradientText>
    </LogoContainer>
  );
};

// 参考来源：https://tailwindcomponents.com/component/simple-responsive-navigation-bar-1
export default () => {
  const dispatch = useDispatch();

  return (
    <nav tw="flex items-center bg-white p-2 md:p-3 flex-wrap">
      {/* LOGO&主页链接 */}
      <Link href="/" tw="p-0 md:p-1 lg:p-2 mr-4 inline-flex items-center">
        <GradientLogo>{_GLOBAL.botName || _GLOBAL.botFirstName}</GradientLogo>
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
          <RouteMenuLink to="/">
            <MenuText>首页</MenuText>
          </RouteMenuLink>
          <MenuLink target="_blank" href="https://blog.gramlabs.org/">
            <MenuText>博客</MenuText>
          </MenuLink>
          <MenuLink target="_blank" href="https://mini.gramlabs.org/community">
            <MenuText>社群</MenuText>
          </MenuLink>
          <RouteMenuLink to="/login">
            <MenuText>后台</MenuText>
          </RouteMenuLink>
          <MenuLink
            onClick={() => {
              dispatch(
                openModal({
                  content: buildPageContentMissingConfirm({ title: "关于" }),
                })
              );
            }}
          >
            <MenuText>关于</MenuText>
          </MenuLink>
          <MenuLink
            onClick={() => {
              dispatch(
                openModal({
                  content: buildPageContentMissingConfirm({
                    title: "快速入门",
                  }),
                })
              );
            }}
            tw="bg-yellow-400"
          >
            <MenuText>快速入门</MenuText>
          </MenuLink>
        </div>
      </div>
    </nav>
  );
};
