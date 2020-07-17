import React from "react";
import tw, { styled } from "twin.macro";

import { UnifiedFlexBox } from "./Unified";

const linkAttrs = {
  target: "_blank",
};

const Link = styled.a.attrs(linkAttrs)`
  ${tw`no-underline`}
`;

const IconLink = styled(Link)`
  ${tw`text-black`}
`;

const NavLink = styled(Link)`
  ${tw`text-gray-900 mb-3`}
`;

export default () => {
  return (
    <footer tw="bg-yellow-400">
      <UnifiedFlexBox tw="py-10 flex-wrap-reverse">
        {/* 品牌信息 */}
        <div tw="w-full lg:w-7/12 flex justify-around lg:justify-start mt-10 lg:mt-0">
          <div tw="self-end lg:self-start">
            <img src="/images/logo-x85.png" />
          </div>
          <div tw="ml-6">
            <p tw="text-black text-xl font-bold">policrmini</p>
            <p tw="text-black text-xs font-bold tracking-wider">
              项目组：Telestd
            </p>
            <p tw="text-black text-xs font-bold tracking-wider">
              隶属于：POLICR
            </p>
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
                <NavLink href="https://t.me/policr_changelog">更新频道</NavLink>
                <NavLink href="#">关于我们</NavLink>
              </div>
              <div tw="flex flex-col">
                <NavLink href="#">编辑百科</NavLink>
                <NavLink href="#">贡献翻译</NavLink>
              </div>
            </div>
          </div>
        </div>
      </UnifiedFlexBox>
    </footer>
  );
};
