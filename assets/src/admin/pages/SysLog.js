import React, { useState } from "react";
import useSWR from "swr";
import tw, { styled } from "twin.macro";
import Select from "react-select";
import { Link as RouteLink, useLocation } from "react-router-dom";
import MoonLoader from "react-spinners/MoonLoader";
import { fromUnixTime, format as formatDateTime, getUnixTime } from "date-fns";

import {
  PageHeader,
  PageBody,
  PageSection,
  PageSectionHeader,
  PageSectionTitle,
} from "../components";
const defaultLevelOption = { value: "all", label: "全部" };
const levelOptions = [
  defaultLevelOption,
  { value: "warn", label: "警告" },
  { value: "error", label: "错误" },
];

const TimeLink = styled(RouteLink)`
  ${tw`no-underline text-orange-600 hover:text-orange-400`}
  ${({ selected }) => (selected ? tw`text-black hover:text-black` : undefined)}
`;

const TerminalLoading = () => {
  return (
    <div tw="flex justify-center">
      <MoonLoader size={25} color="#47A8D8" />
    </div>
  );
};

function logColor(log) {
  switch (log.level) {
    case "error":
      return "#FF4545";
    case "warn":
      return "#FFF145";
    default:
      return "white";
  }
}

function parseTimeRange(timeRange) {
  if (["1h", "6h", "1d", "1w", "2w"].includes(timeRange)) return timeRange;
  return "1d";
}

export default () => {
  const location = useLocation();

  const searchParams = new URLSearchParams(location.search);
  const timeRange = parseTimeRange(searchParams.get("timeRange"));

  const [levelOption, setLevelOption] = useState(defaultLevelOption);
  const { data } = useSWR(`/admin/api/logs?timeRange=${timeRange}`);

  const handleLevelChange = (option) => setLevelOption(option);

  const isLoaded = () => data;

  return (
    <>
      <PageHeader title="系统日志" />
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
                    value={levelOption}
                    options={levelOptions}
                    onChange={handleLevelChange}
                    isSearchable={false}
                  />
                </div>
              </div>
              <div tw="w-8/12 flex items-center justify-around">
                <span>显示过去时间范围的情况：</span>
                <TimeLink
                  to="/admin/sys/logs?timeRange=1h"
                  selected={timeRange == "1h"}
                >
                  1 小时
                </TimeLink>
                <TimeLink
                  to="/admin/sys/logs?timeRange=6h"
                  selected={timeRange == "6h"}
                >
                  6 小时
                </TimeLink>
                <TimeLink
                  to="/admin/sys/logs?timeRange=1d"
                  selected={timeRange == "1d"}
                >
                  1 天
                </TimeLink>
                <TimeLink
                  to="/admin/sys/logs?timeRange=1w"
                  selected={timeRange == "1w"}
                >
                  1 周
                </TimeLink>
                <TimeLink
                  to="/admin/sys/logs?timeRange=2w"
                  selected={timeRange == "2w"}
                >
                  2 周
                </TimeLink>
                {/* TODO：自定义时间区间支持 */}
                {/* <TimeLink href="#">自定义</TimeLink> */}
              </div>
            </div>
          </main>
        </PageSection>
        <PageSection tw="flex-1">
          <PageSectionHeader>
            <PageSectionTitle>模拟终端</PageSectionTitle>
          </PageSectionHeader>
          <main tw="flex-1 flex flex-col mt-2">
            {isLoaded() ? (
              <div
                tw="flex-1 rounded-lg shadow font-mono"
                css={{ backgroundColor: "#474747" }}
              >
                {(data.logs.length == 0
                  ? [
                      {
                        level: "info",
                        message: "无日志记录",
                        timestamp: getUnixTime(new Date()),
                      },
                    ]
                  : data.logs
                ).map((log, index) => (
                  <p
                    key={index}
                    css={{ color: logColor(log) }}
                    tw="px-2 hover:text-black hover:bg-white hover:font-bold"
                  >
                    {formatDateTime(
                      fromUnixTime(log.timestamp),
                      "MM/dd H:mm:ss"
                    )}{" "}
                    [{log.level}] {log.message}
                  </p>
                ))}
              </div>
            ) : (
              <TerminalLoading />
            )}
          </main>
        </PageSection>
      </PageBody>
    </>
  );
};
