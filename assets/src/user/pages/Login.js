import React from "react";
import tw, { styled } from "twin.macro";

import { Title } from "../components";

const TokenInput = styled.input`
  border: 0 solid #e2e8f0;
  border-color: hsl(0, 0%, 80%);
  border-radius: 4px;
  border-width: 1px;
  ${tw`px-2 py-2 text-center box-border appearance-none focus:outline-none focus:shadow-outline focus:border-input-active`};
`;

export default () => {
  return (
    <>
      <Title>后台登录</Title>
      <div tw="flex-1 flex items-center justify-center">
        <div tw="md:w-1/2 my-10 px-4 py-2 rounded shadow-lg bg-gray-100">
          <header tw="text-center mb-4">
            <span>欢迎登录 Mini Admin，您准备好了吗？</span>
          </header>
          <form tw="flex flex-col" action="./admin">
            <label tw="text-sm text-gray-700 mb-1 font-bold">令牌</label>
            <TokenInput
              name="token"
              tw="w-full"
              type="password"
              placeholder="在此粘贴令牌……"
            />

            <span tw="mt-4 text-xs text-gray-500">
              提示：向机器人私聊 <code>/login</code> 命令获取令牌字符串。
            </span>

            <button tw="mt-2 w-full border-transparent rounded text-white shadow py-1 bg-blue-500 font-bold cursor-pointer">
              登录
            </button>
          </form>
        </div>
      </div>
    </>
  );
};
