import React from "react";
import useSWR from "swr";
import { useSelector } from "react-redux";
import "twin.macro";

import {
  PageHeader,
  PageBody,
  PageSection,
  PageLoading,
  NotImplemented,
} from "../components";

function makeEndpoint(chat_id) {
  return `/admin/api/chats/${chat_id}/customs`;
}

export default () => {
  const chatsState = useSelector((state) => state.chats);
  const { data, error } = useSWR(
    chatsState && chatsState.isLoaded ? makeEndpoint(chatsState.selected) : null
  );

  const isLoaded = () => chatsState.isLoaded && data;

  let title = "自定义";
  if (isLoaded()) title += ` / ${data.chat.title}`;

  return (
    <>
      <PageHeader title={title} />
      {isLoaded() ? (
        <PageBody>
          <PageSection>
            <header>
              <span tw="font-bold">已添加好的问题</span>
            </header>
            <main>
              <NotImplemented />
            </main>
          </PageSection>
          <PageSection>
            <header>
              <span tw="font-bold">当前编辑的问题</span>
            </header>
            <main>
              <NotImplemented />
            </main>
          </PageSection>
          <PageSection>
            <header>
              <span tw="font-bold">正在预览的问题</span>
            </header>
            <main>
              <NotImplemented />
            </main>
          </PageSection>
        </PageBody>
      ) : (
        <PageLoading />
      )}
    </>
  );
};
