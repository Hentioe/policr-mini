import React, { useState, useCallback, useEffect } from "react";
import useSWR from "swr";
import tw, { styled } from "twin.macro";
import fetch from "unfetch";
import { useLocation } from "react-router-dom";
import { useDispatch } from "react-redux";
import { parseISO, format } from "date-fns";

import { shown as readonlyShown } from "../slices/readonly";
import {
  PageHeader,
  PageBody,
  PageSection,
  PageLoading,
  PageReLoading,
  LabelledButton,
  FormTextarea,
} from "../components";
import { camelizeJson, toastErrors } from "../helper";

const Title = styled.span`
  color: #2f3235;
  ${tw`text-lg`}
`;

const TabMenu = styled.span`
  ${tw`text-gray-800 cursor-pointer select-none py-1 px-2 border-solid rounded-tl rounded-tr border-2 border-b-0 border-transparent`}
  ${({ active }) => active && tw`border-gray-200`}
`;

const TAB_MENU_EDIT = 0;
const TAB_MENU_PREVIEW = 1;

const makeEndpoint = () => `/admin/api/terms`;

const saveTerm = async ({ content }) => {
  let endpoint = "/admin/api/terms";
  let method = "PUT";
  return fetch(endpoint, {
    method: method,
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      content: content,
    }),
  }).then((r) => camelizeJson(r));
};

const previewTerm = async ({ content }) => {
  const endpoint = `/admin/api/terms/preview`;
  const method = "POST";
  return fetch(endpoint, {
    method: method,
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      content: content,
    }),
  }).then((r) => camelizeJson(r));
};

export default () => {
  const location = useLocation();
  const dispatch = useDispatch();

  const { data, mutate, error } = useSWR(makeEndpoint());
  const [activeTabMenu, setActiveTabMenu] = useState(TAB_MENU_PREVIEW);
  const [editingId, setEditingId] = useState(null);
  const [editingContent, setEditingContent] = useState(null);
  const [isPreviewing, setIsPreviewing] = useState(true);
  const [htmlContent, setHtmlContent] = useState("");

  const initEditingContent = () => {
    setEditingId(null);
    setEditingContent(null);
  };
  const handleEditingContentChange = (e) => setEditingContent(e.target.value);

  const isLoaded = () => !error && data && !data.errors;

  const handleTabMenuClick = useCallback(
    (tabMenu) => {
      if (tabMenu != activeTabMenu) {
        setActiveTabMenu(tabMenu);
      }
    },
    [activeTabMenu]
  );

  useEffect(() => {
    if (activeTabMenu == TAB_MENU_PREVIEW && editingContent != null) {
      async function preview() {
        const result = await previewTerm({ content: editingContent });

        if (result.errors) {
          toastErrors(result.errors);
        } else {
          setIsPreviewing(false);
          setHtmlContent(result.html);
        }
      }

      setIsPreviewing(true);
      preview();
    }
  }, [activeTabMenu, editingContent]);

  const handleSaveClick = useCallback(
    async (e) => {
      e.preventDefault();

      const result = await saveTerm({
        id: editingId,
        content: editingContent,
      });

      if (result.errors) toastErrors(result.errors);
      else {
        // 保存成功
        mutate();
        // 初始化编辑内容
        setActiveTabMenu(TAB_MENU_PREVIEW);
      }
    },
    [editingId, editingContent]
  );

  useEffect(() => {
    // 绑定数据。
    if (data) {
      const term = data.term;

      setEditingContent(term.content || "");
    }
  }, [data]);

  useEffect(() => {
    // 初始化编辑内容
    initEditingContent();
    // 初始化只读显示状态。
    dispatch(readonlyShown(false));
  }, [location]);

  let title = "服务条款";

  useEffect(() => {
    if (data && data.errors) toastErrors(data.errors);
  }, [data]);

  return (
    <>
      <PageHeader title={title} />
      {isLoaded() ? (
        <PageBody>
          <PageSection>
            <header>
              <Title>更新服务条款</Title>
            </header>
            <main>
              <div tw="mt-4">
                <header tw="">
                  <TabMenu
                    active={activeTabMenu === TAB_MENU_EDIT}
                    onClick={() => handleTabMenuClick(TAB_MENU_EDIT)}
                  >
                    编辑
                  </TabMenu>
                  <TabMenu
                    active={activeTabMenu === TAB_MENU_PREVIEW}
                    onClick={() => handleTabMenuClick(TAB_MENU_PREVIEW)}
                  >
                    预览
                  </TabMenu>
                </header>
                {activeTabMenu === TAB_MENU_EDIT && (
                  <div tw="h-96">
                    <FormTextarea
                      tw="w-full h-full bg-gray-100 border-2 border-gray-200"
                      value={editingContent || ""}
                      onChange={handleEditingContentChange}
                    />
                    <span tw="text-xs">
                      提示：此内容需使用 Markdown 格式编写。
                    </span>

                    <div tw="flex mt-2">
                      <div tw="flex-1 pr-10">
                        <LabelledButton
                          label="cancel"
                          onClick={() => setActiveTabMenu(TAB_MENU_PREVIEW)}
                        >
                          取消
                        </LabelledButton>
                      </div>
                      <div tw="flex-1 pl-10">
                        <LabelledButton label="ok" onClick={handleSaveClick}>
                          保存
                        </LabelledButton>
                      </div>
                    </div>
                  </div>
                )}
                {activeTabMenu === TAB_MENU_PREVIEW && (
                  <div>
                    {isPreviewing ? (
                      <div>预览中……</div>
                    ) : (
                      <div tw="m-2 text-gray-800">
                        {htmlContent !== "" ? (
                          <>
                            <header tw="mb-4 text-xs text-black">
                              <span tw="font-bold">
                                {__GLOBAL__.botInfo.name}服务条款
                              </span>
                              <p>
                                {format(
                                  parseISO(data.term.updatedAt),
                                  "yyyy 年 M 月 d 日"
                                )}
                              </p>
                              <p>
                                本条款仅适用于本机器人实例，条款内容由实例运营者编写。本条款和
                                Policr Mini
                                项目本身并无关联，也不受限于该项目。使用本机器人即表示您同意《
                                {__GLOBAL__.botInfo.name}服务条款》。
                              </p>
                              <p>因此，请仔细阅读以下条款内容：</p>
                            </header>
                            <main>
                              <div
                                className="markdown-body"
                                dangerouslySetInnerHTML={{
                                  __html: htmlContent,
                                }}
                              />
                            </main>
                          </>
                        ) : (
                          <div>无内容。</div>
                        )}
                      </div>
                    )}
                  </div>
                )}
              </div>
            </main>
          </PageSection>
        </PageBody>
      ) : error ? (
        <PageReLoading mutate={mutate} />
      ) : (
        <PageLoading />
      )}
    </>
  );
};
