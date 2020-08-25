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

import {
  PageHeader,
  PageLoading,
  PageReLoading,
  PageSection,
  PageSectionHeader,
  PageSectionTitle,
  PageBody,
  ActionButton,
} from "../components";
import { Table, Thead, Tr, Th, Tbody, Td } from "../components/Tables";
import { loadSelected } from "../slices/chats";
import { camelizeJson, toastErrors, toastMessage } from "../helper";

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

function parseTimeRange(timeRange) {
  if (["1d", "1w", "2w", "1m"].includes(timeRange)) return timeRange;
  else return "1d";
}
function parseStatus(status) {
  if (["all", "not_passed", "passed"].includes(status)) return status;
  else return "all";
}

function makeQueryString(status, timeRange) {
  status = parseStatus(status);
  timeRange = parseTimeRange(timeRange);

  let queryString = `?timeRange=${timeRange}`;
  if (status != "all") queryString += `&status=${level}`;

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

    default:
      text = "未知";
  }

  return <span style={{ color: color }}>{text}</span>;
}

async function kickByVerification(id, { ban }) {
  ban = ban === true;
  const endpoint = `/admin/api/verifications/${id}/kick?ban=${ban}`;

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
  const apiQueryString = makeQueryString(status, timeRange);

  const [statusOption, setStatusOption] = useState(findStatusOption(status));

  const handleStatusChange = () => {};

  const { data, error, mutate } = useSWR(
    chatsState && chatsState.isLoaded && chatsState.selected
      ? makeEndpoint(chatsState.selected, apiQueryString)
      : null
  );

  const handleKickClick = async (id) => {
    const result = await kickByVerification(id, { ban: false });

    if (result.errors) {
      toastErrors(result.errors);
    } else if (result.ok) {
      toastMessage(`踢出「${result.verification.targetUserName}」成功。`);
    } else {
      toastErrors("出现了一个不太确定的结果。");
    }
  };

  const handleBanClick = async (id) => {
    const result = await kickByVerification(id, { ban: true });

    if (result.errors) {
      toastErrors(result.errors);
    } else if (result.ok) {
      toastMessage(`封禁「${result.verification.targetUserName}」成功。`);
    } else {
      toastErrors("出现了一个不太确定的结果。");
    }
  };

  const isLoaded = () => chatsState.isLoaded && !error && data && !data.errors;

  let title = "验证记录";
  if (isLoaded()) title += ` / ${data.chat.title}`;

  useEffect(() => {
    if (data && data.errors) toastErrors(data.errors);
    if (isLoaded()) dispatch(loadSelected(data.chat));
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
                  to={`${makeQueryString(statusOption.value, "1d")}`}
                  selected={timeRange == "1d"}
                >
                  1 天
                </TimeLink>
                <TimeLink
                  to={`${makeQueryString(statusOption.value, "1w")}`}
                  selected={timeRange == "1w"}
                >
                  1 周
                </TimeLink>
                <TimeLink
                  to={`${makeQueryString(statusOption.value, "2w")}`}
                  selected={timeRange == "2w"}
                >
                  2 周
                </TimeLink>
                <TimeLink
                  to={`${makeQueryString(statusOption.value, "1m")}`}
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
              <Table tw="mt-3">
                <Thead>
                  <Tr>
                    <Th tw="w-2/12">用户名称</Th>
                    <Th tw="w-2/12">语言代码</Th>
                    <Th tw="w-3/12">加入时间</Th>
                    <Th tw="w-1/12 text-center">用时</Th>
                    <Th tw="w-2/12">状态</Th>
                    <Th tw="w-2/12 text-right">操作</Th>
                  </Tr>
                </Thead>
                <Tbody>
                  {data.verifications.map((v, i) => (
                    <Tr key={v.id}>
                      <Td tw="truncate">{v.targetUserName}</Td>
                      <Td>{v.targetUserLanguageCode || "unknown"}</Td>
                      <Td>
                        {formatDateTime(parseISO(v.insertedAt), dateTimeFormat)}
                      </Td>
                      <Td tw="text-center">
                        {differenceInSeconds(
                          parseISO(v.updatedAt),
                          parseISO(v.insertedAt)
                        )}
                      </Td>
                      <Td>{statusUI(v.status)}</Td>
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
