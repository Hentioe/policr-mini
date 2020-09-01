import React, { useEffect, useState, useCallback } from "react";
import "twin.macro";
import useSWR from "swr";
import { useSelector, useDispatch } from "react-redux";
import Select from "react-select";

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
  HintParagraph,
} from "../components";

import { camelizeJson, toastErrors } from "../helper";

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

const makeEndpoint = (chat_id) => `/admin/api/chats/${chat_id}/scheme`;

const saveScheme = async ({ chatId, modeValue }) => {
  const endpoint = `/admin/api/chats/${chatId}/scheme`;
  let body = null;
  if (modeValue != undefined) {
    if (modeValue === defaultModeOption.value) modeValue = null;
    body = { verification_mode: modeValue };
  }

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
  const [isModeEditing, setIsModeEditing] = useState(false);
  const [isSecondsEditing, setIsSecondsEditing] = useState(true);

  useEffect(() => {
    setModeValue(getModeValueFromData());
  }, [data]);

  const handleModeSelectChange = (option) => {
    setIsModeEditing(true);
    setModeValue(option.value);
  };

  const handleModeEditingCanceling = useCallback(() => {
    setIsModeEditing(false);
    setModeValue(getModeValueFromData());
  });

  const handleSaveMode = useCallback(() => {
    const result = saveScheme({
      id: data.scheme ? data.scheme.id : -1,
      chatId: chatsState.selected,
      modeValue: modeValue,
    });
    if (result.errors) {
      toastErrors(result.errors);
      return;
    }
    setIsModeEditing(false);
    mutate();
  }, [modeValue]);

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
              <PageSectionTitle>验证方式</PageSectionTitle>
            </PageSectionHeader>
            <main>
              <div tw="my-2">
                <Select
                  options={modeOptions}
                  value={modeOptions[modeValue]}
                  onChange={handleModeSelectChange}
                  isSearchable={false}
                />
              </div>
              {isModeEditing && (
                <div tw="flex mt-4">
                  <div tw="flex-1 pr-2 lg:pr-10">
                    <LabelledButton
                      label="cancel"
                      onClick={() => handleModeEditingCanceling()}
                    >
                      取消
                    </LabelledButton>
                  </div>
                  <div tw="flex-1 pl-2 lg:pl-10">
                    <LabelledButton label="ok" onClick={handleSaveMode}>
                      确定
                    </LabelledButton>
                  </div>
                </div>
              )}
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
              <NotImplemented />
            </main>
          </PageSection>
          <PageSection>
            <PageSectionHeader>
              <PageSectionTitle>超时时长</PageSectionTitle>
            </PageSectionHeader>
            <main>
              {data.scheme.seconds || isSecondsEditing ? (
                <NotImplemented />
              ) : (
                <div>
                  <HintParagraph>
                    当前为系统默认，
                    <span
                      tw="underline cursor-pointer select-none"
                      onClick={() => setIsSecondsEditing(true)}
                    >
                      点此修改
                    </span>
                    。
                  </HintParagraph>
                </div>
              )}
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
