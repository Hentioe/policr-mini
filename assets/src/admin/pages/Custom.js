import React, { useState } from "react";
import useSWR from "swr";
import { useSelector } from "react-redux";
import tw, { styled } from "twin.macro";

import {
  PageHeader,
  PageBody,
  PageSection,
  PageLoading,
  NotImplemented,
} from "../components";

const FormSection = styled.div`
  ${tw`flex flex-wrap py-4`}
`;
const FormLable = styled.label`
  ${tw`w-full mb-2 lg:mb-0 lg:w-3/12 font-bold`}
`;

const FormInput = styled.input.attrs({
  type: "text",
})`
  ${tw`text-lg box-border rounded appearance-none shadow border text-gray-700 focus:outline-none focus:shadow-outline`}
`;

function makeEndpoint(chat_id) {
  return `/admin/api/chats/${chat_id}/customs`;
}

export default () => {
  const chatsState = useSelector((state) => state.chats);
  const { data, error } = useSWR(
    chatsState && chatsState.isLoaded && chatsState.selected
      ? makeEndpoint(chatsState.selected)
      : null
  );
  const [editingId, setEditingId] = useState(0); // 为 0 或负数都为 `false`，可适用于只允许正数的 id 判断是否有效
  const [startEditing, setStartEdinting] = useState(true);

  const handleStartEditing = () => setStartEdinting(!startEditing);

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
              <span tw="text-lg font-bold">已添加好的问题</span>
            </header>
            <main>
              <p tw="text-center text-gray-700 font-bold">
                当前未添加任何问题，
                <span
                  tw="underline cursor-pointer"
                  onClick={handleStartEditing}
                >
                  点此添加
                </span>
                。
              </p>
            </main>
          </PageSection>
          <PageSection>
            <header>
              <span tw="text-lg font-bold">当前编辑的问题</span>
            </header>
            <main>
              {startEditing ? (
                <form>
                  <FormSection>
                    <FormLable>选择问题的类型</FormLable>
                    <select tw="w-full lg:w-9/12" defaultValue="Text">
                      <option value="Text">文字提问</option>
                      <option value="Photo">图片提问</option>
                    </select>
                  </FormSection>
                  <FormSection>
                    <FormLable>问题的标题</FormLable>
                    <FormInput tw="w-full lg:w-9/12" />
                  </FormSection>
                  <FormSection>
                    <FormLable>答案1</FormLable>
                    <div tw="w-full lg:w-9/12 flex">
                      <div tw="flex-none flex">
                        <select defaultValue="Text">
                          <option value="Text">正确答案</option>
                          <option value="Photo">错误答案</option>
                        </select>
                      </div>
                      <div tw="flex-1 px-4">
                        <FormInput tw="w-full" />
                      </div>
                      <button tw="flex-none">继续添加</button>
                    </div>
                  </FormSection>
                </form>
              ) : (
                <p tw="text-center text-gray-700 font-bold">
                  请选择或新增一个问题。
                </p>
              )}
            </main>
          </PageSection>
          <PageSection>
            <header>
              <span tw="text-lg font-bold">正在预览的问题</span>
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
