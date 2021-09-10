import React, { useState, useEffect, useCallback } from "react";
import tw, { styled } from "twin.macro";
import { Link as RouteLink, useLocation, useHistory } from "react-router-dom";
import { useDispatch } from "react-redux";
import useSWR from "swr";
import { parseISO, format as formatDateTime } from "date-fns";
import fetch from "unfetch";

import { shown as readonlyShown } from "../slices/readonly";
import {
  PageHeader,
  PageBody,
  PageSection,
  PageSectionHeader,
  PageSectionTitle,
  PageLoading,
  PageReLoading,
  ActionButton,
  Pagination,
  FloatingCard,
} from "../components";
import { Table, Thead, Tr, Th, Tbody, Td } from "../components/Tables";
import { toastErrors, toastMessage, camelizeJson } from "../helper";

const SearchInput = styled.input.attrs({
  type: "text",
})`
  ${tw`py-1 box-border border-0 appearance-none focus:outline-none`};
`;

const ClearText = styled.span`
  ${tw`text-gray-600 text-xs cursor-pointer`}
`;

const TitleLink = styled(RouteLink)`
  ${({ takeovered }) => (takeovered ? tw`text-blue-600` : tw`text-gray-600`)}
`;

const dateTimeFormat = "yyyy-MM-dd HH:mm";

function parseOffset(offset) {
  if (offset) {
    try {
      return parseInt(offset);
    } catch (error) {
      return 0;
    }
  } else return 0;
}

function makeAPIQueryString({ offset = 0, keywords }) {
  let queryString = `?offset=${offset}`;
  if (keywords) queryString += `&keywords=${keywords}`;

  return queryString;
}

function makeEndpoint({ offset, keywords }) {
  let endpoint;
  if (keywords != "") {
    endpoint = "/admin/api/chats/search";
  } else {
    endpoint = "/admin/api/chats/list";
  }

  const queryString = makeAPIQueryString({
    offset: offset,
    keywords: keywords,
  });

  return `${endpoint}${queryString}`;
}

async function leaveChat(id) {
  const endpoint = `/admin/api/chats/${id}/leave`;

  return fetch(endpoint, { method: "PUT" }).then((r) => camelizeJson(r));
}

async function syncChat(id) {
  const endpoint = `/admin/api/chats/${id}/sync`;

  return fetch(endpoint, { method: "PUT" }).then((r) => camelizeJson(r));
}

export default () => {
  const location = useLocation();
  const history = useHistory();
  const dispatch = useDispatch();

  const searchParams = new URLSearchParams(location.search);
  const offsetParam = parseOffset(searchParams.get("offset"));
  const keywordsParam = searchParams.get("keywords") || "";
  const endpoint = makeEndpoint({
    offset: offsetParam,
    keywords: keywordsParam,
  });

  const { data, error, mutate } = useSWR(endpoint);

  const [offset, setOffset] = useState(offsetParam);
  const [searchText, setSearchText] = useState(keywordsParam);
  const [isSearching, setIsSearching] = useState(keywordsParam !== "");
  const [isShowClearText, setIsShowClearText] = useState(false);
  const [hoveredInfo, setHoveredInfo] = useState(undefined);

  const handleSearchTextChange = (e) => setSearchText(e.target.value);
  const handleSearchInputKeyDown = useCallback(
    (e) => {
      const keyCode = e.keyCode;
      if (keyCode != 13 || searchText.trim() == "") return;
      const queryString = makeAPIQueryString({ keywords: searchText });

      history.push(`/admin/sys/managements${queryString}`);
    },
    [searchText, offset]
  );

  const handleClearSearchText = useCallback(() => {
    setSearchText("");
    if (!isSearching) return;
    const queryString = makeAPIQueryString({ offset: 0 });

    history.push(`/admin/sys/managements${queryString}`);
  }, [offset, isSearching]);

  const handleLeaveChat = async (id) => {
    const result = await leaveChat(id);

    if (result.errors) {
      toastErrors(result.errors);
      return;
    }

    if (result.ok) toastMessage(`退出『${result.chat.title}』成功。`);
    else
      toastMessage("不太确定『${result.chat.title}』的退出结果。", {
        type: "warn",
      });

    mutate();
  };

  const handleSyncChatClick = async (id) => {
    const result = await syncChat(id);

    if (result.errors) {
      toastErrors(result.errors);
      return;
    }

    toastMessage(`同步『${result.chat.title}』成功。`);

    mutate();
  };

  const showChatInfo = (c, e) => {
    setHoveredInfo({ chat: c, x: e.pageX, y: e.pageY });
  };

  const hiddenChatInfo = () => setHoveredInfo(undefined);

  useEffect(() => {
    if (searchText && searchText.trim() != "") setIsShowClearText(true);
    else setIsShowClearText(false);
  }, [searchText]);

  useEffect(() => {
    setOffset(offsetParam);
    setIsSearching(keywordsParam !== "");
    // 初始化只读显示状态。
    dispatch(readonlyShown(false));
  }, [location]);

  const isLoaded = () => !error && data;

  return (
    <>
      <PageHeader title="批量管理" />
      <PageBody>
        <PageSection>
          <PageSectionHeader>
            <PageSectionTitle>搜索栏</PageSectionTitle>
          </PageSectionHeader>
          <main tw="py-4 px-6">
            <div tw="p-3 border border-solid border-gray-400 hover:shadow rounded-full flex items-center">
              <SearchInput
                tw="flex-1"
                value={searchText}
                onChange={handleSearchTextChange}
                placeholder="可输入群标题或群组描述中的关键字"
                onKeyDown={handleSearchInputKeyDown}
              />
              {isShowClearText ? (
                <ClearText onClick={handleClearSearchText}>清空</ClearText>
              ) : null}
            </div>
          </main>
        </PageSection>
        <PageSection>
          <PageSectionHeader>
            <PageSectionTitle>群组列表</PageSectionTitle>
          </PageSectionHeader>
          {isLoaded() ? (
            <main>
              <div tw="shadow rounded">
                {hoveredInfo && (
                  <FloatingCard x={hoveredInfo.x} y={hoveredInfo.y}>
                    <header
                      style={{
                        background: hoveredInfo.chat.isTakeOver && "#F1F7FF",
                      }}
                      tw="text-center rounded-t py-2 bg-gray-100"
                    >
                      <span>群组详情</span>
                    </header>
                    <main tw="w-72 text-xs p-2">
                      <div>
                        <label tw="font-bold text-black">标题：</label>
                        <span>{hoveredInfo.chat.title}</span>
                      </div>
                      <div tw="mt-2">
                        <label tw="font-bold text-black">描述：</label>
                        <div tw="py-2">
                          <span tw="tracking-tight">
                            {hoveredInfo.chat.descripion || "无"}
                          </span>
                        </div>
                      </div>
                    </main>
                  </FloatingCard>
                )}
                <Table>
                  <Thead>
                    <Tr>
                      <Th tw="w-4/12">标题</Th>
                      <Th tw="w-3/12">username</Th>
                      <Th tw="w-3/12">加入于</Th>
                      <Th tw="w-2/12 text-right">操作</Th>
                    </Tr>
                  </Thead>
                  <Tbody>
                    {data.chats.map((chat) => (
                      <Tr key={chat.id}>
                        <Td
                          tw="truncate"
                          onMouseEnter={(e) => showChatInfo(chat, e)}
                          onMouseLeave={hiddenChatInfo}
                        >
                          {/* TODO: 此处切换群组会造成一个多余的请求发送，需解决（可能采取和 Chats 组件部分相同的逻辑替代 RouteLink） */}
                          <TitleLink
                            takeovered={chat.isTakeOver ? 1 : 0}
                            to={`/admin/chats/${chat.id}/custom`}
                          >
                            {chat.title}
                          </TitleLink>
                        </Td>
                        <Td tw="truncate">
                          {chat.username ? (
                            <a
                              tw="text-gray-600 no-underline hover:text-blue-400"
                              target="blank"
                              href={`https://t.me/${chat.username}`}
                            >
                              @{chat.username}
                            </a>
                          ) : (
                            "无"
                          )}
                        </Td>
                        <Td>
                          {formatDateTime(
                            parseISO(chat.insertedAt),
                            dateTimeFormat
                          )}
                        </Td>
                        <Td tw="text-right">
                          <ActionButton
                            onClick={() => handleSyncChatClick(chat.id)}
                          >
                            同步
                          </ActionButton>
                          <ActionButton
                            tw="ml-1"
                            onClick={() => handleLeaveChat(chat.id)}
                          >
                            退出
                          </ActionButton>
                        </Td>
                      </Tr>
                    ))}
                  </Tbody>
                </Table>
                <Pagination
                  begin={offset + 1}
                  ending={offset + data.chats.length}
                  linkify={true}
                  upTo={makeAPIQueryString({
                    offset: offset <= 35 ? 0 : offset - 35,
                    keywords: isSearching ? searchText : null,
                  })}
                  downTo={makeAPIQueryString({
                    offset: offset + 35,
                    keywords: isSearching ? searchText : null,
                  })}
                />
              </div>
            </main>
          ) : error ? (
            <PageReLoading />
          ) : (
            <PageLoading />
          )}
        </PageSection>
      </PageBody>
    </>
  );
};
