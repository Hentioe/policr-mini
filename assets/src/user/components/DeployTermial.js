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
        <BashLine>touch docker-compose.yml .env</BashLine>
        <BashLine>
          vi{" "}
          <a
            tw="text-white no-underline hover:underline"
            href="https://github.com/Hentioe/policr-mini/wiki/%E8%87%AA%E8%A1%8C%E9%83%A8%E7%BD%B2%EF%BC%88%E6%9E%84%E5%BB%BA%E7%AC%AC%E4%B8%89%E6%96%B9%E5%AE%9E%E4%BE%8B%EF%BC%89#%E9%85%8D%E7%BD%AE%E5%B9%B6%E5%90%AF%E5%8A%A8"
            target="_blank"
          >
            docker-compose.yml
          </a>
        </BashLine>
        <BashLine>
          vi{" "}
          <a
            tw="text-white no-underline hover:underline"
            href="https://github.com/Hentioe/policr-mini/wiki/%E8%87%AA%E8%A1%8C%E9%83%A8%E7%BD%B2%EF%BC%88%E6%9E%84%E5%BB%BA%E7%AC%AC%E4%B8%89%E6%96%B9%E5%AE%9E%E4%BE%8B%EF%BC%89#%E9%85%8D%E7%BD%AE%E5%B9%B6%E5%90%AF%E5%8A%A8"
            target="_blank"
          >
            .env
          </a>
        </BashLine>
        <BashLine>ls -a</BashLine>
        <Line>
          <File>
            <a
              tw="text-white no-underline hover:underline"
              href="https://github.com/Hentioe/policr-mini/wiki/%E8%87%AA%E8%A1%8C%E9%83%A8%E7%BD%B2%EF%BC%88%E6%9E%84%E5%BB%BA%E7%AC%AC%E4%B8%89%E6%96%B9%E5%AE%9E%E4%BE%8B%EF%BC%89#%E9%85%8D%E7%BD%AE%E5%B9%B6%E5%90%AF%E5%8A%A8"
              target="_blank"
            >
              docker-compose.yml
            </a>
          </File>
          <File>
            <a
              tw="text-white no-underline hover:underline"
              href="https://github.com/Hentioe/policr-mini/wiki/%E8%87%AA%E8%A1%8C%E9%83%A8%E7%BD%B2%EF%BC%88%E6%9E%84%E5%BB%BA%E7%AC%AC%E4%B8%89%E6%96%B9%E5%AE%9E%E4%BE%8B%EF%BC%89#%E9%85%8D%E7%BD%AE%E5%B9%B6%E5%90%AF%E5%8A%A8"
              target="_blank"
            >
              .env
            </a>
          </File>
        </Line>
        <BashLine>sudo docker-compose up -d</BashLine>
        <Line>
          Creating policr-mini_db_1 ... <span tw="text-green-500">done</span>
        </Line>
        <Line>
          Creating policr-mini_server_1 ...{" "}
          <span tw="text-green-500">done</span>
        </Line>
        <BashLine>ls -a</BashLine>
        <Line>
          <Dir>_assets</Dir>
          <Dir>_data</Dir>
          <File>docker-compose.yml</File>
          <File>.env</File>
        </Line>
        <BashLine>sudo docker logs policr-mini_server_1</BashLine>
        <Line>...................</Line>
        <Line>00:00:00.100 [info] Checking bot information ...</Line>
        <Line>00:00:00.200 [info] Bot (@your_bot_username) is working</Line>
      </div>
    </div>
  );
};
