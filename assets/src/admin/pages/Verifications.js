import React, { useEffect, useState } from "react";
import useSWR from "swr";
import { useSelector, useDispatch } from "react-redux";
import { Link as RouteLink, useLocation } from "react-router-dom";
import tw, { styled } from "twin.macro";
import Select from "react-select";

import {
  PageHeader,
  PageLoading,
  PageReLoading,
  PageSection,
  PageSectionHeader,
  PageSectionTitle,
  PageBody,
} from "../components";
import { loadSelected } from "../slices/chats";

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
      {isLoaded() ? (
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
        </PageBody>
      ) : error ? (
        <PageReLoading mutate={mutate} />
      ) : (
        <PageLoading />
      )}
    </>
  );
};
