import React from "react";
import tw, { styled } from "twin.macro";

const TitleBarIcon = styled.div`
  ${tw`inline-block mr-2 rounded-full w-3 h-3 select-none`}
`;

const Line = styled.div`
  ${tw`mb-1`}
`;

const BashLine = styled(Line)`
  &:before {
    content: "bash:~$";
    margin-right: 0.5rem;
    color: #40b900;
    font-weight: 600;
  }
`;

const File = styled.span`
  ${tw`mr-2`}
`;

const Dir = styled(File)`
  ${tw`text-blue-500`}
`;

export default () => {
  return (
    <div tw="rounded-t-lg shadow-lg">
      <header tw="rounded-t-lg bg-gray-200 px-4 py-2">
        <div tw="absolute">
          <TitleBarIcon tw="bg-red-500" />
          <TitleBarIcon tw="bg-green-500" />
          <TitleBarIcon tw="bg-yellow-500" />
        </div>
        <div tw="text-center text-gray-600 font-medium">~ : ssh - mini</div>
      </header>
      <div
        style={{ background: "#636363" }}
        tw="bg-white p-4 text-xs md:text-sm text-white font-mono font-medium"
      >
        <BashLine>ls -a</BashLine>
        <Line>
          <Dir>_data</Dir>
          <File>docker-compose.yml</File>
          <Dir>.env</Dir>
          <Dir>images</Dir>
        </Line>
        <BashLine>vi .env</BashLine>
        <BashLine>sudo docker-compose up -d</BashLine>
        <Line>
          Creating policr-mini_db_1 ... <span tw="text-green-500">done</span>
        </Line>
        <Line>
          Creating policr-mini_server_1 ...{" "}
          <span tw="text-green-500">done</span>
        </Line>
        <BashLine>sudo docker logs policr-mini_server_1</BashLine>
        <Line>00:00:00.100 [info] Already up</Line>
        <Line>
          00:00:00.200 [info] Running PolicrMiniWeb.Endpoint with cowboy 2.8.0
          at :::8080 (http)
        </Line>
        <Line>
          00:00:00.300 [info] Access PolicrMiniWeb.Endpoint at
          http://localhost:8080
        </Line>
        <Line>00:00:00.400 [info] Checking bot information…</Line>
        <Line>00:00:00.500 [info] Bot (@your_bot_username) is working</Line>
      </div>
    </div>
  );
};
