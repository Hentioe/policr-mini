import React, { useEffect, useState } from "react";
import useSWR from "swr";
import { useSelector, useDispatch } from "react-redux";
import { Link as RouteLink, useLocation } from "react-router-dom";
import tw, { styled } from "twin.macro";
import Select from "react-select";
import fetch from "unfetch";
import {
  parseISO,
  format as formatDateTime,
  differenceInSeconds,
} from "date-fns";

import { loadSelected } from "../slices/chats";
import { shown as readonlyShown } from "../slices/readonly";
import {
  PageHeader,
  PageLoading,
  PageReLoading,
  PageSection,
  PageSectionHeader,
  PageSectionTitle,
  PageBody,
  ActionButton,
  Pagination,
  FloatingCard,
} from "../components";
import { Table, Thead, Tr, Th, Tbody, Td } from "../components/Tables";
import {
  camelizeJson,
  toastErrors,
  toastMessage,
  usePrevious,
} from "../helper";

const TimeLink = styled(RouteLink)`
  ${tw`no-underline text-orange-600 hover:text-orange-400`}
  ${({ selected }) => (selected ? tw`text-black hover:text-black` : undefined)}
`;

const defaultStatusOption = { value: "all", label: "不限" };
const statusOptions = [
  defaultStatusOption,
  { value: "not_passed", label: "未通过" },
  { value: "passed", label: "已通过" },
];

function findStatusOption(value) {
  const options = statusOptions.filter((option) => option.value === value);

  if (options.length == 0) return defaultStatusOption;
  else return options[0];
}

function parseOffset(offset) {
  if (offset) {
    try {
      return parseInt(offset);
    } catch (error) {
      return 0;
    }
  } else return 0;
}

function parseTimeRange(timeRange) {
  if (["1d", "1w", "2w", "1m"].includes(timeRange)) return timeRange;
  else return "1d";
}
function parseStatus(status) {
  if (["all", "not_passed", "passed"].includes(status)) return status;
  else return "all";
}

function makeQueryString({ status, timeRange, offset }) {
  status = parseStatus(status);
  timeRange = parseTimeRange(timeRange);
  offset = parseOffset(offset);

  let queryString = `?timeRange=${timeRange}&offset=${offset}`;
  if (status != "all") queryString += `&status=${status}`;

  return queryString;
}

function statusUI(status) {
  let color;
  let text;
  switch (status) {
    case "waiting":
      color = "khaki";
      text = "等待";
      break;
    case "passed":
      color = "green";
      text = "通过";
      break;
    case "timeout":
      color = "red";
      text = "超时";
      break;
    case "wronged":
      color = "red";
      text = "错误";
      break;
    case "expired":
      color = "darkkhaki";
      text = "过期";
      break;
    case "manual_ban":
      color = "#26DBD9";
      text = "手动封禁";
      break;
    case "manual_kick":
      color = "#269DDB";
      text = "手动踢出";
      break;

    default:
      text = "未知";
  }

  return <span style={{ color: color }}>{text}</span>;
}

const STATUS_BG_COLOR_MAPPING = {
  waiting: "#FFFFEB",
  passed: "#EFFFEE",
  timeout: "#FFF1F1",
  wronged: "#FFF1F1",
};

async function killByVerification(id, action) {
  const endpoint = `/admin/api/verifications/${id}/kill?action=${action}`;

  return fetch(endpoint, { method: "PUT" }).then((r) => camelizeJson(r));
}

const dateTimeFormat = "yyyy-MM-dd HH:mm:ss";

const makeEndpoint = (chatId, queryString) =>
  `/admin/api/chats/${chatId}/verifications${queryString}`;

export default () => {
  const dispatch = useDispatch();
  const location = useLocation();

  const chatsState = useSelector((state) => state.chats);
  const searchParams = new URLSearchParams(location.search);

  const status = searchParams.get("status");
  const timeRange = parseTimeRange(searchParams.get("timeRange"));
  const offset = parseOffset(searchParams.get("offset"));
  const apiQueryString = makeQueryString({ status, timeRange, offset });

  const [statusOption, _setStatusOption] = useState(findStatusOption(status));
  const [hoveredInfo, setHoveredInfo] = useState(undefined);

  const prevLocaltion = usePrevious(location);

  const handleStatusChange = () => {};

  const { data, error, mutate } = useSWR(
    chatsState && chatsState.isLoaded && chatsState.selected
      ? makeEndpoint(chatsState.selected, apiQueryString)
      : null
  );

  const handleKickClick = async (id) => {
    const result = await killByVerification(id, "manual_kick");

    if (result.errors) {
      toastErrors(result.errors);
    } else if (result.ok) {
      toastMessage(`踢出「${result.verification.targetUserName}」成功。`);
    } else {
      toastErrors(
        `无法确定踢出「${result.verification.targetUserName}」是否成功。`
      );
    }
  };

  const handleBanClick = async (id) => {
    const result = await killByVerification(id, "manual_ban");

    if (result.errors) {
      toastErrors(result.errors);
    } else if (result.ok) {
      toastMessage(`封禁「${result.verification.targetUserName}」成功。`);
    } else {
      toastErrors(
        `无法确定封禁「${result.verification.targetUserName}」是否成功。`
      );
    }
  };

  const showUserInfo = (v, e) => {
    setHoveredInfo({ verification: v, x: e.pageX, y: e.pageY });
  };

  const hiddenUserInfo = () => setHoveredInfo(undefined);

  const isLoaded = () => chatsState.isLoaded && !error && data && !data.errors;

  let title = "验证记录";
  if (isLoaded()) title += ` / ${data.chat.title}`;

  useEffect(() => {
    // 避免二次点击链接后重新初始化
    if (prevLocaltion == null || prevLocaltion.pathname != location.pathname) {
      // 初始化只读显示状态
      dispatch(readonlyShown(false));
    }
  }, []);

  useEffect(() => {
    if (data && data.errors) toastErrors(data.errors);
    if (isLoaded()) {
      dispatch(loadSelected(data.chat));
      dispatch(readonlyShown(!data.writable));
    }
  }, [data]);

  return (
    <>
      <PageHeader title={title} />
      <PageBody>
        <PageSection>
          <PageSectionHeader>
            <PageSectionTitle>过滤器</PageSectionTitle>
          </PageSectionHeader>
          <main>
            <div tw="flex py-2">
              <div tw="w-4/12 flex items-center">
                <span>级别：</span>
                <div css={{ width: "5.5rem" }}>
                  <Select
                    value={statusOption}
                    options={statusOptions}
                    onChange={handleStatusChange}
                    isSearchable={false}
                  />
                </div>
              </div>
              <div tw="w-8/12 flex items-center justify-around">
                <span>显示过去时间范围的情况：</span>
                <TimeLink
                  to={makeQueryString({
                    status: statusOption.value,
                    timeRange: "1d",
                    offset: offset,
                  })}
                  selected={timeRange == "1d"}
                >
                  1 天
                </TimeLink>
                <TimeLink
                  to={makeQueryString({
                    status: statusOption.value,
                    timeRange: "1w",
                    offset: offset,
                  })}
                  selected={timeRange == "1w"}
                >
                  1 周
                </TimeLink>
                <TimeLink
                  to={makeQueryString({
                    status: statusOption.value,
                    timeRange: "2w",
                    offset: offset,
                  })}
                  selected={timeRange == "2w"}
                >
                  2 周
                </TimeLink>
                <TimeLink
                  to={makeQueryString({
                    status: statusOption.value,
                    timeRange: "1m",
                    offset: offset,
                  })}
                  selected={timeRange == "1m"}
                >
                  1 月
                </TimeLink>
              </div>
            </div>
          </main>
        </PageSection>
        <PageSection>
          <PageSectionHeader>
            <PageSectionTitle>验证列表</PageSectionTitle>
          </PageSectionHeader>
          <main>
            {isLoaded() ? (
              <div tw="shadow rounded">
                {hoveredInfo && (
                  // 用户信息浮动卡片。
                  <FloatingCard x={hoveredInfo.x} y={hoveredInfo.y}>
                    <header
                      style={{
                        background:
                          STATUS_BG_COLOR_MAPPING[
                            hoveredInfo.verification.status
                          ],
                      }}
                      tw="text-center rounded-t py-2 bg-gray-100"
                    >
                      <span tw="font-bold">用户详情</span>
                    </header>

                    <div tw="p-3">
                      <div tw="text-xs">
                        <label tw="font-bold text-black">全名</label>：
                        <div tw="py-2">
                          <span tw="text-gray-600 tracking-tight">
                            {hoveredInfo.verification.targetUserName}
                          </span>
                        </div>
                      </div>
                      <div tw="text-xs">
                        <label tw="font-bold text-black">ID</label>：
                        <span tw="text-gray-600 font-mono">
                          {hoveredInfo.verification.targetUserId}
                        </span>
                      </div>
                    </div>
                  </FloatingCard>
                )}
                <Table tw="mt-3">
                  <Thead>
                    <Tr>
                      <Th tw="w-2/12">用户名称</Th>
                      <Th tw="w-2/12">语言代码</Th>
                      <Th tw="w-3/12">加入时间</Th>
                      <Th tw="w-1/12 text-center">用时</Th>
                      <Th tw="w-2/12 text-center">状态</Th>
                      <Th tw="w-2/12 text-right">操作</Th>
                    </Tr>
                  </Thead>
                  <Tbody>
                    {data.verifications.map((v) => (
                      <Tr key={v.id}>
                        <Td
                          tw="truncate"
                          onMouseEnter={(e) => showUserInfo(v, e)}
                          onMouseLeave={hiddenUserInfo}
                        >
                          {v.targetUserName}
                        </Td>
                        <Td>{v.targetUserLanguageCode || "unknown"}</Td>
                        <Td>
                          {formatDateTime(
                            parseISO(v.insertedAt),
                            dateTimeFormat
                          )}
                        </Td>
                        <Td tw="text-center">
                          {differenceInSeconds(
                            parseISO(v.updatedAt),
                            parseISO(v.insertedAt)
                          )}
                        </Td>
                        <Td tw="text-center">{statusUI(v.status)}</Td>
                        <Td tw="text-right">
                          <ActionButton
                            onClick={() => handleBanClick(v.id)}
                            tw="mr-1"
                          >
                            封禁
                          </ActionButton>
                          <ActionButton onClick={() => handleKickClick(v.id)}>
                            踢出
                          </ActionButton>
                        </Td>
                      </Tr>
                    ))}
                  </Tbody>
                </Table>
                <Pagination
                  begin={offset + 1}
                  ending={offset + data.verifications.length}
                  linkify={true}
                  upTo={makeQueryString({
                    status,
                    timeRange,
                    offset: offset < 25 ? 0 : offset - 25,
                  })}
                  downTo={makeQueryString({
                    status,
                    timeRange,
                    offset: offset + 25,
                  })}
                />
              </div>
            ) : error ? (
              <PageReLoading mutate={mutate} />
            ) : (
              <PageLoading />
            )}
          </main>
        </PageSection>
      </PageBody>
    </>
  );
};
