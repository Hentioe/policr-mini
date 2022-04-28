import React, { useEffect } from "react";
import tw, { styled } from "twin.macro";
import { useLocation } from "react-router-dom";
import { useDispatch } from "react-redux";
import useSWR from "swr";
import {
  parseISO,
  format as formatDateTime,
  differenceInSeconds,
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
  LabelledButton,
} from "../components";
import { shown as readonlyShown } from "../slices/readonly";

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

const makeEndpoint = () => `/admin/api/tasks`;

export default () => {
  const location = useLocation();
  const dispatch = useDispatch();

  const { data, error } = useSWR(makeEndpoint());

  const isLoaded = () => !error && data && !data.errors;

  const title = "系统任务";

  useEffect(() => {
    // 初始化只读显示状态
    dispatch(readonlyShown(false));
  }, [location]);

  return (
    <>
      <PageHeader title={title} />
      <PageBody>
        <PageSection>
          <header>
            <PageSectionTitle>定时任务</PageSectionTitle>
          </header>
          <main>
            {isLoaded() ? (
              <div>
                {data.jobs.map((job, i) => (
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
                  <span tw="text-gray-600 text-xs tracking-wider">
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
