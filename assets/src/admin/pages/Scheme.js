import React, { useState } from "react";
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

const defaultModeOption = { value: 4, label: "系统默认" };
const modeOptions = [
  { value: 0, label: "图片验证" },
  { value: 1, label: "定制验证" },
  { value: 2, label: "算术验证" },
  { value: 3, label: "主动验证" },
  defaultModeOption,
];

const makeEndpoint = (chat_id) => `/admin/api/chats/${chat_id}/scheme`;

export default () => {
  const chatsState = useSelector((state) => state.chats);

  const { data } = useSWR(
    chatsState && chatsState.isLoaded && chatsState.selected
      ? makeEndpoint(chatsState.selected)
      : null
  );
  const modeOption =
    data && data.scheme && data.scheme.verificationMode
      ? modeOptions[data.scheme.verificationMode]
      : defaultModeOption;

  const [modeValue, setModeValue] = useState(modeOption.value);
  const [isModeEditing, setIsModeEditing] = useState(false);

  const handleModeSelectChange = (option) => {
    setIsModeEditing(true);
    setModeValue(option.value);
  };

  const handleCancelModeEditing = () => {
    setIsModeEditing(false);
    setModeValue(modeOption.value);
  };

  const isLoaded = () => chatsState.isLoaded && data;

  let title = "验证方案";
  if (isLoaded()) title += ` / ${data.chat.title}`;

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
                />
              </div>
              {isModeEditing && (
                <div tw="flex mt-4">
                  <div tw="flex-1 pr-10">
                    <LabelledButton
                      label="cancel"
                      onClick={handleCancelModeEditing}
                    >
                      取消
                    </LabelledButton>
                  </div>
                  <div tw="flex-1 pl-10">
                    <LabelledButton label="ok">确定</LabelledButton>
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
        </PageBody>
      ) : (
        <PageLoading />
      )}
    </>
  );
};
