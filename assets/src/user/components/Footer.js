import React from "react";
import tw, { styled } from "twin.macro";
import { useDispatch } from "react-redux";
import { Link as RouteLink } from "react-router-dom";

import waveSvg from "../../../static/svg/wave.svg";
import mobileBgSvg from "../../../static/svg/footer_bg_mobile.svg";

import { open as openModal } from "../slices/modal";
import Confirm from "./Confirm";
import { UnifiedFlexBox } from "./Unified";
import BackgroundContainer from "./BackgroundContainer";

const linkAttrs = {
  target: "_blank",
};

const Link = styled.a.attrs(linkAttrs)`
  ${tw`no-underline`}
`;

const IconLink = styled(Link)`
  ${tw`text-gray-800`}
`;

const NavLink = styled(Link)`
  ${tw`no-underline text-gray-900 mb-3 cursor-pointer`}
`;

const RouteNavLink = styled(RouteLink)`
  ${tw`no-underline text-gray-900 mb-3 cursor-pointer`}
`;

const buildPageContentMissingConfirm = ({ title }) => (
  <Confirm title={title}>
    <span tw="text-gray-600">
      由于此项目暂未完全实现，此页面内容有待填充。更多细节请参阅
      <a
        tw="text-blue-600"
        target="_blank"
        href="https://t.me/policr_changelog"
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

export default () => {
  const dispatch = useDispatch();

  return (
    <BackgroundContainer tw="bg-bottom" src={waveSvg} mobileSrc={mobileBgSvg}>
      <UnifiedFlexBox tw="py-10 flex-wrap-reverse">
        {/* 品牌信息 */}
        <div tw="w-full lg:w-7/12 flex justify-around lg:justify-start mt-10 lg:mt-0">
          <div tw="self-end lg:self-start">
            <img src="/images/logo-85x85.png" />
          </div>
          <div tw="ml-6 text-black">
            <p tw="text-xl font-bold tracking-wide">policrmini</p>
            <p tw="text-xs font-bold tracking-wider">
              项目组：
              <a tw="text-black" target="_blank" href="https://gramlabs.org/">
                GramLabs
              </a>
            </p>
            <p tw="text-xs text-gray-800 tracking-wider leading-relaxed">
              GramLabs 是一个部分开源的 Telegram 技术社区，含义是“Telegram
              实验室”。GramLabs 正在尝试孵化一些 Telegram 生态的基础应用。
            </p>
            <p tw="text-xs font-bold tracking-wider">隶属于：POLICR</p>
          </div>
        </div>
        <div tw="w-full lg:w-5/12 flex justify-center lg:justify-end">
          <div tw="mr-8 lg:mr-16">
            <IconLink href="https://mini.gramlabs.org/community" tw="mr-2">
              <i
                style={{ fontSize: 24 }}
                className="iconfont icon-telegram"
              ></i>
            </IconLink>
            <IconLink href="https://github.com/Hentioe/policr-mini">
              <i style={{ fontSize: 24 }} className="iconfont icon-github"></i>
            </IconLink>
          </div>
          <div>
            <div tw="flex">
              <div tw="flex flex-col mr-16">
                <NavLink href="https://mini.gramlabs.org/community">
                  社区群组
                </NavLink>
                <NavLink
                  onClick={() => {
                    dispatch(
                      openModal({
                        content: buildPageContentMissingConfirm({
                          title: "关于我们",
                        }),
                      })
                    );
                  }}
                >
                  关于我们
                </NavLink>
                <RouteNavLink to="/terms">服务条款</RouteNavLink>
              </div>
              <div tw="flex flex-col">
                <NavLink href="https://t.me/policr_changelog">更新频道</NavLink>
                <NavLink target="_blank" href="https://blog.gramlabs.org/">
                  博客动态
                </NavLink>
                <NavLink
                  onClick={() => {
                    dispatch(
                      openModal({
                        content: (
                          <Confirm title="贡献翻译">
                            <span tw="text-gray-600">
                              由于此项目暂未完全实现，当前不考虑对多语言的支持。可关注
                              <a
                                tw="text-blue-600"
                                target="_blank"
                                href="https://t.me/policr_changelog"
                              >
                                更新频道
                              </a>
                              等待后续安排，感谢您。
                            </span>
                          </Confirm>
                        ),
                      })
                    );
                  }}
                >
                  贡献翻译
                </NavLink>
              </div>
            </div>
          </div>
        </div>
      </UnifiedFlexBox>
    </BackgroundContainer>
  );
};
