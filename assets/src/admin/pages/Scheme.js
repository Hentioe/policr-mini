import React, { useEffect, useState, useCallback } from "react";
import useSWR from "swr";
import { useSelector, useDispatch } from "react-redux";
import Select from "react-select";
import tw, { styled } from "twin.macro";

import { loadSelected } from "../slices/chats";
import {
  PageHeader,
  PageBody,
  PageSection,
  PageSectionHeader,
  PageSectionTitle,
  PageLoading,
  PageReLoading,
  NotImplemented,
  LabelledButton,
  FormInput,
} from "../components";

import { camelizeJson, toastErrors } from "../helper";

const Comment = styled.div`
  ${tw`text-sm text-gray-500`}
`;

const defaultModeOption = { value: 4, label: "系统默认" };
const modeOptions = [
  { value: 0, label: "图片验证" },
  { value: 1, label: "定制验证（自定义）" },
  { value: 2, label: "算术验证" },
  { value: 3, label: "主动验证" },
  defaultModeOption,
];
const modeMapping = {
  image: 0,
  custom: 1,
  arithmetic: 2,
  initiative: 3,
};

const customSecondsOption = { value: "custom", label: "自定义" };
const defaultSecondsOption = { value: "default", label: "系统默认" };
const secondsOptions = [
  { value: 45, label: "自动生成：超短" },
  { value: 75, label: "自动生成：较短" },
  { value: 150, label: "自动生成：一般" },
  { value: 300, label: "自动生成：较长" },
  defaultSecondsOption,
  customSecondsOption,
];

const defaultKillingMethodOption = { value: null, label: "系统默认" };
const killingMethodOptions = [
  { value: 1, label: "踢出（封禁再延时解禁）" },
  { value: 0, label: "封禁" },
  defaultKillingMethodOption,
];

const makeEndpoint = (chat_id) => `/admin/api/chats/${chat_id}/scheme`;

const saveScheme = async ({
  chatId,
  verificationMode,
  seconds,
  timeoutKillingMethod,
  wrongKillingMethod,
}) => {
  const endpoint = `/admin/api/chats/${chatId}/scheme`;
  let body = null;
  if (verificationMode === defaultModeOption.value) verificationMode = null;
  if (seconds == "") seconds = null;

  body = {
    verification_mode: verificationMode,
    seconds: seconds,
    timeout_killing_method: timeoutKillingMethod,
    wrong_killing_method: wrongKillingMethod,
  };

  return fetch(endpoint, {
    method: "PUT",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  }).then((r) => camelizeJson(r));
};

export default () => {
  const dispatch = useDispatch();
  const chatsState = useSelector((state) => state.chats);

  const { data, error, mutate } = useSWR(
    chatsState && chatsState.isLoaded && chatsState.selected
      ? makeEndpoint(chatsState.selected)
      : null
  );

  const getModeValueFromData = useCallback(() => {
    return data && data.scheme && data.scheme.verificationMode
      ? modeMapping[data.scheme.verificationMode]
      : defaultModeOption.value;
  }, [data]);

  const [modeValue, setModeValue] = useState(defaultModeOption.value);
  const [isEdited, setIsEdited] = useState(false);
  const [editingSecondsOption, setEditingSecondsOption] =
    useState(defaultSecondsOption);
  const [
    editingTimeoutKillingMethodOption,
    setEditingTimeoutKillingMethodOption,
  ] = useState(defaultKillingMethodOption);
  const [editingWrongKillingMethodOption, setEditingWrongKillingMethodOption] =
    useState(defaultKillingMethodOption);

  const [editingSeconds, setEditingSeconds] = useState(0);

  useEffect(() => {
    rebind();
  }, [data]);

  const rebind = useCallback(() => {
    setModeValue(getModeValueFromData());

    if (data && data.scheme) {
      const { seconds, timeoutKillingMethod, wrongKillingMethod } = data.scheme;

      setEditingSeconds(seconds || "");
      if (seconds == null) setEditingSecondsOption(defaultSecondsOption);
      else setEditingSecondsOption(customSecondsOption);

      if (timeoutKillingMethod == null)
        setEditingTimeoutKillingMethodOption(defaultKillingMethodOption);
      else if (timeoutKillingMethod == "kick")
        setEditingTimeoutKillingMethodOption(killingMethodOptions[0]);
      else if (timeoutKillingMethod == "ban")
        setEditingTimeoutKillingMethodOption(killingMethodOptions[1]);

      if (wrongKillingMethod == null)
        setEditingWrongKillingMethodOption(defaultKillingMethodOption);
      else if (wrongKillingMethod == "kick")
        setEditingWrongKillingMethodOption(killingMethodOptions[0]);
      else if (wrongKillingMethod == "ban")
        setEditingWrongKillingMethodOption(killingMethodOptions[1]);
    }
  });

  const handleModeSelectChange = (option) => {
    setIsEdited(true);
    setModeValue(option.value);
  };

  const handleEditingSecondsSelectChange = (option) => {
    setIsEdited(true);
    setEditingSecondsOption(option);

    if (!isNaN(option.value)) {
      setEditingSeconds(option.value);
    } else {
      setEditingSeconds("");
    }
  };

  const handleEditingSecondsChange = (e) => {
    setIsEdited(true);

    const value = e.target.value;
    if (![45, 75, 150, 300].includes(value)) {
      setEditingSecondsOption(customSecondsOption);
    }
    setEditingSeconds(e.target.value);
  };

  const handleEditingTimeoutKillingMethodSelectChange = (option) => {
    setIsEdited(true);

    setEditingTimeoutKillingMethodOption(option);
  };

  const handleEditingWrongKillingMethodSelectChange = (option) => {
    setIsEdited(true);

    setEditingWrongKillingMethodOption(option);
  };

  const handleSaveCancel = useCallback(() => {
    setIsEdited(false);

    rebind();
  });

  const handleSaveScheme = useCallback(async () => {
    const result = await saveScheme({
      id: data.scheme ? data.scheme.id : -1,
      chatId: chatsState.selected,
      verificationMode: modeValue,
      seconds: editingSeconds,
      timeoutKillingMethod: editingTimeoutKillingMethodOption.value,
      wrongKillingMethod: editingWrongKillingMethodOption.value,
    });

    if (result.errors) {
      toastErrors(result.errors);
      return;
    }
    setIsEdited(false);
    mutate();
  }, [
    modeValue,
    editingSeconds,
    editingTimeoutKillingMethodOption,
    editingWrongKillingMethodOption,
  ]);

  const isLoaded = () => !error && chatsState.isLoaded && data && !data.errors;

  let title = "方案定制";
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
              <PageSectionTitle>验证方法</PageSectionTitle>
            </PageSectionHeader>
            <main>
              <div tw="my-2">
                <Comment>
                  说明：提供有多项验证方法，主要分以下几类：
                  <ul>
                    <li>在已存储资源的基础上随机：图片验证、定制验证。</li>
                    <li>纯动态：算数验证。</li>
                    <li>纯静态：主动验证。</li>
                  </ul>
                </Comment>
                <div tw="flex flex-wrap items-center">
                  <div tw="w-3/12">
                    <label>修改方法</label>
                  </div>
                  <div tw="w-9/12">
                    <Select
                      tw="mt-2"
                      options={modeOptions}
                      value={modeOptions[modeValue]}
                      onChange={handleModeSelectChange}
                      isSearchable={false}
                    />
                  </div>
                </div>
              </div>
            </main>
          </PageSection>
          <PageSection>
            <PageSectionHeader>
              <PageSectionTitle>验证场合</PageSectionTitle>
            </PageSectionHeader>
            <main>
              <NotImplemented />
            </main>
          </PageSection>
          <PageSection>
            <PageSectionHeader>
              <PageSectionTitle>验证入口</PageSectionTitle>
            </PageSectionHeader>
            <main>
              <NotImplemented />
            </main>
          </PageSection>
          <PageSection>
            <PageSectionHeader>
              <PageSectionTitle>击杀方法</PageSectionTitle>
            </PageSectionHeader>
            <main>
              <div tw="py-2">
                <Comment>
                  提示：可独立设置验证超时或验证错误的击杀方法。一般来讲：
                  <ul>
                    <li>
                      验证超时的用户为 Spam bot
                      的可能性极大，封禁有较小的概率误伤正常帐号。
                    </li>
                    <li>
                      验证错误的用户为真人的概率很大，但也存在很多以发广告为目的进群的真人。
                    </li>
                  </ul>
                  <span>
                    系统默认的击杀方法总是宽容的，不一定适合所有群。请根据群组自己设置的验证难度和进群门槛选择适合的击杀方法。
                  </span>
                </Comment>

                <div tw="flex flex-wrap items-center">
                  <div tw="w-3/12">
                    <label>验证超时</label>
                  </div>
                  <div tw="w-9/12">
                    <Select
                      tw="mt-2"
                      options={killingMethodOptions}
                      value={editingTimeoutKillingMethodOption}
                      onChange={handleEditingTimeoutKillingMethodSelectChange}
                      isSearchable={false}
                    />
                  </div>
                  <div tw="w-3/12">
                    <label>验证错误</label>
                  </div>
                  <div tw="w-9/12">
                    <Select
                      tw="mt-2"
                      options={killingMethodOptions}
                      value={editingWrongKillingMethodOption}
                      onChange={handleEditingWrongKillingMethodSelectChange}
                      isSearchable={false}
                    />
                  </div>
                </div>
              </div>
            </main>
          </PageSection>
          <PageSection>
            <PageSectionHeader>
              <PageSectionTitle>超时时长</PageSectionTitle>
            </PageSectionHeader>
            <main>
              <div tw="my-2">
                <Comment>
                  提示：请设置合理的验证时间，这里有一些建议：
                  <ul>
                    <li>最短不低于 40 秒。</li>
                    <li>最长不高于 600 秒（10 分钟）。</li>
                  </ul>
                </Comment>
                <div tw="mt-2 flex items-center">
                  <div tw="w-3/12">
                    <label>设置值</label>
                  </div>
                  <div tw="flex flex-1">
                    <Select
                      tw="mr-2"
                      styles={{
                        control: (provided) => ({
                          ...provided,
                          width: 200,
                        }),
                      }}
                      options={secondsOptions}
                      onChange={handleEditingSecondsSelectChange}
                      isSearchable={false}
                      value={editingSecondsOption}
                    />
                    <FormInput
                      type="number"
                      tw="flex-1 text-center"
                      value={editingSeconds}
                      onChange={handleEditingSecondsChange}
                      placeholder={
                        editingSecondsOption.value == "default"
                          ? "系统默认值"
                          : "在此填入秒数"
                      }
                    />
                  </div>
                </div>
              </div>
            </main>
          </PageSection>
          {isEdited ? (
            <PageSection>
              <PageSectionHeader>
                <PageSectionTitle>保存修改</PageSectionTitle>
              </PageSectionHeader>
              <main>
                <div tw="flex mt-4">
                  <div tw="flex-1 pr-2 lg:pr-10">
                    <LabelledButton label="cancel" onClick={handleSaveCancel}>
                      取消
                    </LabelledButton>
                  </div>
                  <div tw="flex-1 pl-2 lg:pl-10">
                    <LabelledButton label="ok" onClick={handleSaveScheme}>
                      确定
                    </LabelledButton>
                  </div>
                </div>
              </main>
            </PageSection>
          ) : undefined}
        </PageBody>
      ) : error ? (
        <PageReLoading mutate={mutate} />
      ) : (
        <PageLoading />
      )}
    </>
  );
};
