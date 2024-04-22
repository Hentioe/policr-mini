import React, { useEffect } from "react";
import tw, { styled } from "twin.macro";
import { useLocation } from "react-router-dom";
import { useDispatch } from "react-redux";
import useSWR from "swr";
import {
  parseISO,
  format as formatDateTime
} from "date-fns";

const dateTimeFormat = "yyyy-MM-dd HH:mm:ss";

import {
  PageHeader,
  PageBody,
  PageSection,
  Title,
  PageSectionTitle,
  PageReLoading,
  PageLoading,
  ActionButton,
} from "../components";
import { shown as readonlyShown } from "../slices/readonly";
import { camelizeJson, toastErrors, toastMessage } from "../helper";

const Job = styled.div`
  ${tw`w-full pt-4`}
  ${tw`border-0 border-solid border-b border-gray-200`}
`;

const JobName = styled.span`
  ${tw`text-gray-700 font-bold text-sm tracking-wide`}
`;

const JobDetail = styled.div`
  ${tw`my-3`}
`;

const JobDetailName = styled.span`
  ${tw`text-gray-700 inline-block w-40 mr-10 text-sm`}
`;

const JobDetailValue = styled.span`
  ${tw`text-gray-600 text-sm`}
`;


async function resetStats() {
  const endpoint = `/admin/api/tasks/reset_stats`;

  return fetch(endpoint, { method: "PUT" }).then((r) => camelizeJson(r));
}

function renderJobName(id) {
  switch (id) {
    case "reset_all_stats":
      return "重置统计数据"
  }

  return "未知"
}

function renderStatus(status) {
  switch (status) {
    case "pending":
      return "等待中"
    case "running":
      return "运行中"
    case "done":
      return "已完成"
  }

  return "未知"
}

const makeEndpoint = () => `/admin/api/tasks`;

export default () => {
  const location = useLocation();
  const dispatch = useDispatch();

  const { data, error, mutate } = useSWR(makeEndpoint());

  const isLoaded = () => !error && data && !data.errors;

  const title = "系统任务";

  useEffect(() => {
    // 初始化只读显示状态
    dispatch(readonlyShown(false));
  }, [location]);

  const handleResetStats = () => {
    resetStats().then((data) => {
      if (data.errors) {
        toastErrors(data.errors);
      } else {
        toastMessage("任务开始执行，留意任务列表变化");

        mutate();
      }
    });
  };

  const JobResult = ({ result }) => {
    // 如果 result 是 Object，则展示为 JSON
    if (typeof result === "object") {
      return <pre tw="bg-gray-100 p-2 rounded"><code>{JSON.stringify(result, null, 2)}</code></pre>
    }

    return <span>{result}</span>
  }


  const StatefulJobs = ({ jobs }) => {
    if (jobs.length === 0) {
      return <p tw="text-center text-lg font-bold text-gray-400">空</p>
    }
    return <div>
      {data.statefulJobs.map((job) => (
        <Job key={job.name}>
          <JobName>{renderJobName(job.name)}</JobName>
          <JobDetail>
            <JobDetailName>状态</JobDetailName>
            <JobDetailValue>{renderStatus(job.status)}</JobDetailValue>
          </JobDetail>
          <JobDetail>
            <JobDetailName>开始于</JobDetailName>
            <JobDetailValue tw="tracking-wide">
              {formatDateTime(
                parseISO(job.startAt),
                dateTimeFormat
              )}
            </JobDetailValue>
          </JobDetail>
          <JobDetail>
            <JobDetailName>结束于</JobDetailName>
            <JobDetailValue tw="tracking-wide">
              {job.endAt ? formatDateTime(
                parseISO(job.endAt),
                dateTimeFormat
              ) : "无"}
            </JobDetailValue>
          </JobDetail>
          <JobDetail>
            <JobDetailName>结果</JobDetailName>
            <JobDetailValue>
              <JobResult result={job.result} />
            </JobDetailValue>
          </JobDetail>
        </Job>
      ))}
    </div>
  }

  return (
    <>
      <PageHeader title={title} />
      <PageBody>
        <PageSection>
          <header>
            <PageSectionTitle>任务中心</PageSectionTitle>
            <ActionButton onClick={handleResetStats} tw="mx-2">↻ 重置统计</ActionButton>
          </header>
          <main>
            {isLoaded() ? <StatefulJobs jobs={data.statefulJobs} /> : error ? (
              <PageReLoading />
            ) : (
              <PageLoading />
            )}
          </main>
        </PageSection>
        <PageSection>
          <header>
            <PageSectionTitle>定时任务</PageSectionTitle>
          </header>
          <main>
            {isLoaded() ? (
              <div>
                {data.scheduledJobs.map((job) => (
                  <Job key={job.name}>
                    <JobName>{job.nameText}</JobName>
                    <JobDetail>
                      <JobDetailName>执行周期</JobDetailName>
                      <JobDetailValue>{job.scheduleText}</JobDetailValue>
                    </JobDetail>
                    <JobDetail>
                      <JobDetailName>下次执行于</JobDetailName>
                      <JobDetailValue tw="tracking-wide">
                        {formatDateTime(
                          parseISO(job.nextRunDatetime),
                          dateTimeFormat
                        )}
                      </JobDetailValue>
                    </JobDetail>
                    <JobDetail>
                      <JobDetailName>时区</JobDetailName>
                      <JobDetailValue>{job.timezone}</JobDetailValue>
                    </JobDetail>
                  </Job>
                ))}

                <div tw="pt-6">
                  <span tw="text-gray-500 text-sm tracking-wider">
                    定时任务通常是用于修正系统中存在的错误状态或数据的一系列特殊任务，它们由系统自身创建和调度。
                  </span>
                </div>
              </div>
            ) : error ? (
              <PageReLoading />
            ) : (
              <PageLoading />
            )}
          </main>
        </PageSection>
      </PageBody>
    </>
  );
};
