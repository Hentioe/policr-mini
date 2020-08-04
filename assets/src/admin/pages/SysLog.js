import React, { useState } from "react";
import useSWR from "swr";
import tw, { styled } from "twin.macro";
import Select from "react-select";
import MoonLoader from "react-spinners/MoonLoader";
import { fromUnixTime, format as formatDateTime } from "date-fns";

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

const TimeLink = styled.a`
  ${tw`no-underline text-orange-600 hover:text-orange-400`}
  ${tw`mx-2`}
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

export default () => {
  const [levelOption, setLevelOption] = useState(defaultLevelOption);
  const { data } = useSWR("/admin/api/logs");

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
              <div tw="w-8/12 flex items-center">
                <label>显示过去时间范围的情况：</label>
                <TimeLink href="#">1 小时</TimeLink>
                <TimeLink href="#">6 小时</TimeLink>
                <TimeLink href="#">1 天</TimeLink>
                <TimeLink href="#">1 周</TimeLink>
                <TimeLink href="#">2 周</TimeLink>
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
                {data.logs.map((log) => (
                  <p
                    css={{ color: logColor(log) }}
                    tw="px-2 hover:text-black hover:bg-white hover:font-bold"
                  >
                    {formatDateTime(
                      fromUnixTime(log.timestamp),
                      "yyyy-MM-dd H:mm:ss"
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
