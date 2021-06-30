import React from "react";
import tw, { styled } from "twin.macro";
import { useDispatch } from "react-redux";
import { Link as RouteLink } from "react-router-dom";

import { open as openModal } from "../slices/modal";
import Confirm from "./Confirm";
import { UnifiedFlexBox } from "./Unified";

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
        href="https://mini.telestd.me/community"
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
    <footer style={{ background: "url(/svg/footer_bg.svg)" }}>
      <UnifiedFlexBox tw="py-10 flex-wrap-reverse">
        {/* 品牌信息 */}
        <div tw="w-full lg:w-7/12 flex justify-around lg:justify-start mt-10 lg:mt-0">
          <div tw="self-end lg:self-start">
            <img src="/images/logo-85x85.png" />
          </div>
          <div tw="ml-6 text-black">
            <p tw="text-xl font-bold">policrmini</p>
            <p tw="text-xs font-bold tracking-wider">项目组：Telestd</p>
            <p tw="text-xs font-bold tracking-wider">隶属于：POLICR</p>
          </div>
        </div>
        <div tw="w-full lg:w-5/12 flex justify-center lg:justify-end">
          <div tw="mr-8 lg:mr-16">
            <IconLink href="https://mini.telestd.me/community" tw="mr-2">
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
                <NavLink href="https://mini.telestd.me/community">
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
                <NavLink
                  onClick={() => {
                    dispatch(
                      openModal({
                        content: buildPageContentMissingConfirm({
                          title: "编辑百科",
                        }),
                      })
                    );
                  }}
                >
                  编辑百科
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
    </footer>
  );
};
