import React, { useState, useCallback } from "react";
import tw, { styled } from "twin.macro";
import { useDispatch } from "react-redux";

import { close } from "../slices/modal";

const Button = styled.button`
  ${tw`border-0 rounded shadow bg-blue-500 text-white font-bold py-2 cursor-pointer`}
`;

export default ({ instanceName, botUsername }) => {
  const dispatch = useDispatch();

  const [readed, setReaded] = useState(false);

  const handleReadedClick = useCallback(() => {
    setReaded(true);
  }, [readed]);

  return (
    <div tw="bg-white rounded shadow-xl p-4">
      <header tw="text-center pb-2 border-0 border-b border-solid border-gray-400">
        <span tw="text-gray-900 font-bold">邀请{instanceName}进群需知</span>
      </header>
      <p tw="text-gray-900 text-sm">
        当前 Policr Mini
        项目缺乏对第三方实例可靠性的检测机制，并且无法担保第三方实例的安全性。如果您清楚选择此实例所提供的服务将可能承担的风险，您当然可以使用它。
        否则，请选择一个您认为最值得信任的实例。
      </p>

      <p tw="text-gray-900 text-sm">
        通过「我已阅读并自愿承担风险」按钮可生成此机器人的邀请链接。若您发现此实例运营者有滥用权限的迹象，可向我们（Policr
        Mini 项目）举报以将此实例移出此列表。
      </p>

      <div tw="flex justify-between items-center">
        {!readed && (
          <Button onClick={handleReadedClick}>我已阅读并自愿承担风险</Button>
        )}
        {readed && (
          <a
            tw="text-white py-2 px-2 text-sm bg-blue-500 rounded shadow"
            href={`https://t.me/${botUsername}`}
            target="_blank"
          >
            邀请我入群
          </a>
        )}

        <Button tw="bg-gray-500" onClick={() => dispatch(close())}>
          容我再想想吧
        </Button>
      </div>
    </div>
  );
};
