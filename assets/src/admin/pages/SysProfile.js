import React, { useEffect, useState, useCallback } from "react";
import useSWR from "swr";
import { useDispatch } from "react-redux";
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
  LabelledButton,
  FormInput,
} from "../components";

const OwnSelect = styled(Select)`
  ${tw`w-8/12`}
`;

const FormLine = styled.div`
  ${tw`flex items-center mt-4`}
`;

const FormLabel = styled.label`
  ${tw`w-4/12 text-gray-700`}
`;

const FromHint = ({ children }) => {
  return (
    <div tw="flex">
      <div tw="w-4/12"></div>
      <span tw="w-8/12 mt-1 text-gray-600 text-xs font-bold">{children}</span>
    </div>
  );
};

import { camelizeJson, toastErrors } from "../helper";

const modeOptions = [
  { value: 0, label: "图片验证" },
  { value: 1, label: "定制验证（自定义）" },
  { value: 2, label: "算术验证" },
  { value: 3, label: "主动验证" },
];
const modeMapping = {
  image: 0,
  custom: 1,
  arithmetic: 2,
  initiative: 3,
};

const killingMethodOptions = [
  { value: 1, label: "踢出（封禁再延时解禁）" },
  { value: 0, label: "封禁" },
];

const mentionTextOptions = [
  { value: 0, label: "用户 ID" },
  { value: 1, label: "用户全名" },
  { value: 2, label: "马赛克全名" },
];

const saveScheme = async ({
  verificationMode,
  seconds,
  timeoutKillingMethod,
  wrongKillingMethod,
  mentionText,
}) => {
  const endpoint = `/admin/api/profile/scheme`;

  const body = {
    verification_mode: verificationMode,
    seconds: seconds,
    timeout_killing_method: timeoutKillingMethod,
    wrong_killing_method: wrongKillingMethod,
    mention_text: mentionText,
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

  const { data, error, mutate } = useSWR("/admin/api/profile");

  const getModeValueFromData = useCallback(() => {
    return (
      data &&
      data.scheme &&
      data.scheme.verificationMode &&
      modeMapping[data.scheme.verificationMode]
    );
  }, [data]);

  const [modeValue, setModeValue] = useState(null);
  const [isEdited, setIsEdited] = useState(false);
  const [
    editingTimeoutKillingMethodOption,
    setEditingTimeoutKillingMethodOption,
  ] = useState(null);
  const [editingWrongKillingMethodOption, setEditingWrongKillingMethodOption] =
    useState(null);

  const [editingSeconds, setEditingSeconds] = useState(0);
  const [editingMentionTextOption, setEditingMentionTextOption] =
    useState(null);

  useEffect(() => {
    rebind();
  }, [data]);

  const rebind = useCallback(() => {
    setModeValue(getModeValueFromData());

    if (data && data.scheme) {
      const { seconds, timeoutKillingMethod, wrongKillingMethod, mentionText } =
        data.scheme;

      setEditingSeconds(seconds || "");

      if (timeoutKillingMethod == "kick")
        setEditingTimeoutKillingMethodOption(killingMethodOptions[0]);
      else if (timeoutKillingMethod == "ban")
        setEditingTimeoutKillingMethodOption(killingMethodOptions[1]);

      if (wrongKillingMethod == "kick")
        setEditingWrongKillingMethodOption(killingMethodOptions[0]);
      else if (wrongKillingMethod == "ban")
        setEditingWrongKillingMethodOption(killingMethodOptions[1]);

      if (mentionText == "user_id")
        setEditingMentionTextOption(mentionTextOptions[0]);
      else if (mentionText == "full_name")
        setEditingMentionTextOption(mentionTextOptions[1]);
      else if (mentionText == "mosaic_full_name")
        setEditingMentionTextOption(mentionTextOptions[2]);
    }
  });

  const handleModeSelectChange = (option) => {
    setIsEdited(true);
    setModeValue(option.value);
  };

  const handleEditingSecondsChange = (e) => {
    setIsEdited(true);

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

  const handleEditingMentionTextOptionChange = (option) => {
    setIsEdited(true);

    setEditingMentionTextOption(option);
  };

  const handleSaveCancel = useCallback(() => {
    setIsEdited(false);

    rebind();
  });

  const handleSaveScheme = useCallback(async () => {
    const result = await saveScheme({
      id: data.scheme ? data.scheme.id : -1,
      verificationMode: modeValue,
      seconds: editingSeconds,
      timeoutKillingMethod: editingTimeoutKillingMethodOption.value,
      wrongKillingMethod: editingWrongKillingMethodOption.value,
      mentionText: editingMentionTextOption.value,
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
    editingMentionTextOption,
  ]);

  const isLoaded = () => !error && data && !data.errors;

  let title = "全局属性";

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
              <PageSectionTitle>修改验证方案的默认值</PageSectionTitle>
            </PageSectionHeader>
            <main>
              <form>
                <FormLine>
                  <FormLabel>验证方式</FormLabel>
                  <OwnSelect
                    options={modeOptions}
                    value={modeOptions[modeValue]}
                    onChange={handleModeSelectChange}
                    isSearchable={false}
                  />
                </FormLine>
                <FromHint>
                  请不要轻易设置为「定制验证」，因为不是所有群都添加有自定义回答数据
                </FromHint>
                <FormLine>
                  <FormLabel>击杀方法（验证超时）</FormLabel>
                  <OwnSelect
                    options={killingMethodOptions}
                    value={editingTimeoutKillingMethodOption}
                    onChange={handleEditingTimeoutKillingMethodSelectChange}
                    isSearchable={false}
                  />
                </FormLine>
                <FromHint>针对验证结果为「超时」的用户采取的措施</FromHint>
                <FormLine>
                  <FormLabel>击杀方法（验证错误）</FormLabel>
                  <OwnSelect
                    options={killingMethodOptions}
                    value={editingWrongKillingMethodOption}
                    onChange={handleEditingWrongKillingMethodSelectChange}
                    isSearchable={false}
                  />
                </FormLine>
                <FromHint>针对验证结果为「错误」的用户采取的措施</FromHint>
                <FormLine>
                  <FormLabel>超时时间</FormLabel>

                  <FormInput
                    type="number"
                    tw="w-8/12 text-center"
                    value={editingSeconds}
                    onChange={handleEditingSecondsChange}
                    placeholder="在此填入秒数"
                  />
                </FormLine>
                <FromHint>单个用户的验证等待时间，单位：秒</FromHint>
                <FormLine>
                  <FormLabel>提及文本</FormLabel>
                  <OwnSelect
                    options={mentionTextOptions}
                    value={editingMentionTextOption}
                    onChange={handleEditingMentionTextOptionChange}
                    isSearchable={false}
                  />
                </FormLine>
                <FromHint>
                  提及验证用户时显示的内容，马赛克指用符号遮挡部分文字
                </FromHint>
              </form>
            </main>
          </PageSection>

          {/* <PageSection>
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
          </PageSection> */}
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
