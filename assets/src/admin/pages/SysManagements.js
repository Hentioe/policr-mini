import React, { useState, useEffect } from "react";
import tw, { styled } from "twin.macro";
import { Link as RouteLink, useLocation } from "react-router-dom";
import useSWR from "swr";
import { parseISO, format as formatDateTime } from "date-fns";

import {
  PageHeader,
  PageBody,
  PageSection,
  PageSectionHeader,
  PageSectionTitle,
  PageLoading,
  PageReLoading,
} from "../components";

const SearchInput = styled.input.attrs({
  type: "text",
})`
  ${tw`py-1 box-border border-0 appearance-none focus:outline-none`};
`;

const ClearText = styled.span`
  ${tw`text-gray-600 text-xs cursor-pointer`}
`;

const TableHeaderCell = styled.th`
  ${tw`font-normal text-gray-500 text-left uppercase pr-6`}
`;

const TableDataRow = styled.tr``;
const TableDataCell = styled.td(() => [
  tw`border border-dashed border-0 border-t border-gray-300`,
  tw`py-2`,
]);

const OperatingText = styled.span`
  ${tw`text-xs text-blue-400 font-bold cursor-pointer`}
`;

const TitleLink = styled(RouteLink)`
  ${({ takeovered }) => (takeovered ? tw`text-blue-600` : tw`text-gray-600`)}
`;

const PaginationLink = styled(RouteLink).attrs(({ disabled }) => ({
  disabled: disabled,
}))`
  ${tw`no-underline`}
  ${({ disabled }) =>
    disabled ? tw`pointer-events-none text-gray-300` : tw`text-gray-600`}
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

function makeAPIQueryString({ offset, keywords }) {
  let queryString = `offset=${offset}`;
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

  return `${endpoint}?${queryString}`;
}

export default () => {
  const location = useLocation();

  const searchParams = new URLSearchParams(location.search);
  const offsetParam = parseOffset(searchParams.get("offset"));
  const keywordsParam = searchParams.get("keywords") || "";
  const endpoint = makeEndpoint({
    offset: offsetParam,
    keywords: keywordsParam,
  });

  const { data, error } = useSWR(endpoint);

  const [offset, setOffset] = useState(offsetParam);
  const [searchText, setSearchText] = useState(keywordsParam);
  const [isShowClearText, setIsShowClearText] = useState(false);

  const handleSearchTextChange = (e) => setSearchText(e.target.value);
  const handleClearSearchText = () => setSearchText("");

  useEffect(() => {
    if (searchText && searchText.trim() != "") setIsShowClearText(true);
    else setIsShowClearText(false);
  }, [searchText]);

  useEffect(() => {
    setOffset(offsetParam);
  }, [location]);

  const isLoaded = () => !error && data;

  return (
    <>
      <PageHeader title="批量管理" />
      {isLoaded() ? (
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
            <main>
              <table tw="w-full border border-solid border-0 border-b border-t border-gray-300 mt-1">
                <thead>
                  <tr>
                    <TableHeaderCell>标题</TableHeaderCell>
                    <TableHeaderCell>username</TableHeaderCell>
                    <TableHeaderCell>上次修改</TableHeaderCell>
                    <TableHeaderCell>加入于</TableHeaderCell>
                    <TableHeaderCell>操作</TableHeaderCell>
                  </tr>
                </thead>
                <tbody>
                  {data.chats.map((chat) => (
                    <TableDataRow key={chat.id}>
                      <TableDataCell>
                        {/* TODO: 此处切换群组会造成一个多余的请求发送，需解决（可能采取和 Chats 组件部分相同的逻辑替代 RouteLink） */}
                        <TitleLink
                          takeovered={chat.isTakeOver ? 1 : 0}
                          to={`/admin/chats/${chat.id}/custom`}
                        >
                          {chat.title}
                        </TitleLink>
                      </TableDataCell>
                      <TableDataCell>{chat.username || "空"}</TableDataCell>
                      <TableDataCell>
                        {formatDateTime(
                          parseISO(chat.updatedAt),
                          dateTimeFormat
                        )}
                      </TableDataCell>
                      <TableDataCell>
                        {formatDateTime(
                          parseISO(chat.insertedAt),
                          dateTimeFormat
                        )}
                      </TableDataCell>
                      <TableDataCell>
                        <OperatingText tw="mr-1">同步</OperatingText>
                        <OperatingText>退出</OperatingText>
                      </TableDataCell>
                    </TableDataRow>
                  ))}
                </tbody>
              </table>
              <div tw="mt-2 flex justify-between">
                <PaginationLink
                  disabled={offset == 0}
                  to={`/admin/sys/managements?offset=${
                    offset <= 25 ? 0 : offset - 25
                  }`}
                >
                  上一页
                </PaginationLink>
                <span>
                  {data.chats.length == 0
                    ? `没有第 ${offset + 1} 条往后的记录`
                    : `从 ${offset + 1} 条起到第 ${
                        offset + data.chats.length
                      } 条记录`}
                </span>
                <PaginationLink
                  disabled={data.chats.length == 0}
                  to={`/admin/sys/managements?offset=${offset + 25}`}
                >
                  下一页
                </PaginationLink>
              </div>
            </main>
          </PageSection>
        </PageBody>
      ) : error ? (
        <PageReLoading />
      ) : (
        <PageLoading />
      )}
    </>
  );
};
