import React from "react";
import tw, { styled } from "twin.macro";

import { Title } from "../components";

const UnifiedBox = styled.div.attrs({})`
  ${tw`mx-10`}
`;

const UnifiedFlexBox = styled(UnifiedBox).attrs({})`
  ${tw`flex`}
`;

const InlineKeybordButton = styled.div.attrs({})`
  ${tw`shadow-sm bg-blue-400 text-white rounded-md px-4 py-2 text-sm mt-1 flex justify-center bg-opacity-75 cursor-pointer`}
`;

export default () => {
  return (
    <>
      <Title>首页</Title>
      <UnifiedFlexBox tw="flex-wrap mt-20">
        <div tw="w-8/12">
          <p tw="text-blue-500 text-4xl font-bold tracking-widest">
            社区驱动的开源验证机器人，致力于自助部署和使用。
          </p>
          <p tw="text-gray-500">
            本项目从 Policr
            机器人的开发和运营过程中吸取了丰富的经验，设计更加现代。不新增、不膨胀，单一而专注的同时将持续优化本职功能和体验。欢迎有资源的人加入我们，共建社区生态。
          </p>
        </div>
        <div tw="w-4/12 flex content-between flex-col justify-between">
          {/* 验证入口消息, 开始 */}
          <div tw="flex justify-between">
            <div tw="w-2/12 self-end">
              <img
                src="/images/avatarx75.jpg"
                tw="w-12 rounded-full shadow-sm"
              />
            </div>
            <div tw="w-10/12">
              <div tw="shadow rounded-md p-4 text-sm">
                新成员 <span tw="text-blue-500 cursor-pointer">机░人</span>{" "}
                你好！
                <br />
                您当前需要完成验证才能解除限制，验证有效时间不超过{" "}
                <span tw="underline">300</span> 秒。过期会被踢出或封禁，请尽快。
              </div>
              <div tw="mt-2">
                <InlineKeybordButton>
                  <span tw="underline">点此验证</span>
                </InlineKeybordButton>
              </div>
            </div>
          </div>
          {/* 验证入口消息, 结束 */}
          {/* 验证消息，开始 */}
          <div tw="flex justify-between mt-2">
            <div tw="w-2/12 self-end">
              <img
                src="/images/avatarx75.jpg"
                tw="w-12 rounded-full shadow-sm"
              />
            </div>
            <div tw="w-10/12">
              <div tw="shadow rounded-md text-sm">
                <img src="/images/etx400.jpg" tw="w-full rounded-t" />
                <div tw="px-4 py-1">
                  <p tw="italic">
                    来自『<span tw="font-bold">POLICR · 中文社区</span>
                    』的验证，请确认问题并选择您认为正确的答案。
                  </p>
                  <p tw="font-bold">图片中的事物是？</p>
                  <p>
                    您还剩 <span tw="underline">198</span> 秒，通过可解除封印。
                  </p>
                </div>
              </div>
              <div tw="mt-2">
                <InlineKeybordButton>
                  <span>地铁</span>
                </InlineKeybordButton>
                <InlineKeybordButton>
                  <span>公路</span>
                </InlineKeybordButton>
                <InlineKeybordButton>
                  <span>外星人</span>
                </InlineKeybordButton>
              </div>
            </div>
          </div>
          {/* 验证消息，结束 */}
        </div>
      </UnifiedFlexBox>
    </>
  );
};
