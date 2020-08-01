import React, { useEffect, useState, useCallback } from "react";
import useSWR from "swr";
import { useSelector } from "react-redux";
import "twin.macro";
import Select from "react-select";

import {
  PageHeader,
  PageBody,
  PageSection,
  PageSectionHeader,
  PageSectionTitle,
  PageLoading,
  NotImplemented,
  LabelledButton,
} from "../components";

import { camelizeJson, toastError, isNoPermissions } from "../helper";

const defaultModeOption = { value: 4, label: "系统默认" };
const modeOptions = [
  { value: 0, label: "图片验证" },
  { value: 1, label: "定制验证" },
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

const saveScheme = ({ chatId, modeValue }) => {
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
  const chatsState = useSelector((state) => state.chats);

  const { data, mutate } = useSWR(
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
    saveScheme({
      id: data.scheme ? data.scheme.id : -1,
      chatId: chatsState.selected,
      modeValue: modeValue,
    }).then((result) => {
      if (result.errors) toastError("修改失败了。");
      else {
        setIsModeEditing(false);
        mutate();
      }
    });
  }, [modeValue]);

  const isLoaded = () => chatsState.isLoaded && data;

  let title = "验证方案";
  if (isLoaded() && !isNoPermissions(data)) title += ` / ${data.chat.title}`;

  useEffect(() => {
    if (isLoaded() && isNoPermissions(data)) toastError("您没有访问权限。");
  }, [data]);

  return (
    <>
      <PageHeader title={title} />
      {isLoaded() && !isNoPermissions(data) ? (
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
                />
              </div>
              {isModeEditing && (
                <div tw="flex mt-4">
                  <div tw="flex-1 pr-10">
                    <LabelledButton
                      label="cancel"
                      onClick={() => handleModeEditingCanceling()}
                    >
                      取消
                    </LabelledButton>
                  </div>
                  <div tw="flex-1 pl-10">
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
              <PageSectionTitle>击杀方式</PageSectionTitle>
            </PageSectionHeader>
            <main>
              <NotImplemented />
            </main>
          </PageSection>
        </PageBody>
      ) : (
        <PageLoading />
      )}
    </>
  );
};
