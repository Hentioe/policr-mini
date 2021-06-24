import React from "react";
import tw from "twin.macro";
import useSWR from "swr";
import { parseISO, format } from "date-fns";

import { Title, ErrorParagraph } from "../components";

const fetcher = (url) => fetch(url).then((r) => r.json());

export default () => {
  const { data, error } = useSWR("/api/terms", fetcher);

  if (error)
    return <ErrorParagraph>载入条款内容失败，请稍后重试。</ErrorParagraph>;

  const isLoaded = () => !error && data && !data.errors;

  return (
    <>
      <Title>服务条款</Title>
      <div tw="flex-1 mx-4 md:px-64 py-10 tracking-widest md:tracking-wider">
        {isLoaded() ? (
          <>
            <header tw="mb-4 text-xs text-black">
              <span tw="font-bold">
                {_GLOBAL.botName || _GLOBAL.botFirstName}服务条款
              </span>
              <p>
                {format(parseISO(data.term.updated_at), "yyyy 年 M 月 d 日")}
              </p>
              <p>
                本条款仅适用于本机器人实例，条款内容由实例运营者编写。本条款和
                Policr Mini
                项目本身并无关联，也不受限于该项目。使用本机器人即表示您同意《
                {_GLOBAL.botName || _GLOBAL.botFirstName}服务条款》。
              </p>
              <p>因此，请仔细阅读以下条款内容：</p>
            </header>
            <main>
              {data.term.content == null || data.term.content.trim() == "" ? (
                <p>无服务条款，或未撰写任何内容。</p>
              ) : (
                <div
                  className="markdown-body"
                  dangerouslySetInnerHTML={{
                    __html: data.html_content,
                  }}
                />
              )}
            </main>
          </>
        ) : (
          <div>载入中……</div>
        )}
      </div>
    </>
  );
};
