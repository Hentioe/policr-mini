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

const OwnSelect = styled(Select)`
  ${tw`w-8/12`}
`;

const FormLine = styled.div`
  ${tw`flex items-center mt-4`}
`;

const FormLabel = styled.label`
  ${tw`w-4/12 text-gray-700`}
`;

const ProfileLine = styled.div`
  ${tw`flex items-center mt-4`}
`;

const ProfileLabel = styled.label`
  ${tw`w-4/12 text-gray-700`}
`;

const ProfileValue = styled.label`
  ${tw`w-8/12 text-gray-700`}
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

const defaultMentionTextOption = { value: null, label: "系统默认" };
const mentionTextOptions = [
  { value: 0, label: "用户 ID" },
  { value: 1, label: "用户全名" },
  { value: 2, label: "马赛克全名" },
  defaultMentionTextOption,
];

const modeValueMapping = {
  image: "图片验证",
  custom: "定制验证（自定义）",
  arithmetic: "算数验证",
  initiative: "主动验证",
};

const killMethodMapping = {
  kick: "踢出（封禁再延时解禁）",
  ban: "封禁",
};

const mentionTextMapping = {
  user_id: "用户 ID",
  full_name: "用户全名",
  mosaic_full_name: "马赛克全名",
};

const makeEndpoint = (chat_id) => `/admin/api/chats/${chat_id}/scheme`;

const saveScheme = async ({
  chatId,
  verificationMode,
  seconds,
  timeoutKillingMethod,
  wrongKillingMethod,
  mentionText,
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
  const chatsState = useSelector((state) => state.chats);

  const { data, error, mutate } = useSWR(
    chatsState && chatsState.isLoaded && chatsState.selected
      ? makeEndpoint(chatsState.selected)
      : null
  );

  const { data: profileData, error: profileError } =
    useSWR("/admin/api/profile");

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

      if (mentionText == null)
        setEditingMentionTextOption(defaultMentionTextOption);
      else if (mentionText == "user_id")
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
      chatId: chatsState.selected,
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
              <PageSectionTitle>修改方案</PageSectionTitle>
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
                  自定义问答需修改此处为「定制验证」才可生效，取消选择其它即可
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
                  <div tw="w-8/12 flex flex-1">
                    <div tw="pr-2">
                      <Select
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
                    </div>
                    <div tw="flex-1">
                      <FormInput
                        type="number"
                        tw="w-full text-center"
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

          <PageSection>
            <PageSectionHeader>
              <PageSectionTitle>系统默认值</PageSectionTitle>
            </PageSectionHeader>
            {profileData ? (
              <main>
                <div>
                  <ProfileLine>
                    <ProfileLabel>验证方式</ProfileLabel>
                    <ProfileValue>
                      {modeValueMapping[profileData.scheme.verificationMode]}
                    </ProfileValue>
                  </ProfileLine>
                  <FormLine>
                    <FormLabel>击杀方法（验证超时）</FormLabel>
                    <ProfileValue>
                      {
                        killMethodMapping[
                          profileData.scheme.timeoutKillingMethod
                        ]
                      }
                    </ProfileValue>
                  </FormLine>
                  <FormLine>
                    <FormLabel>击杀方法（验证错误）</FormLabel>
                    <ProfileValue>
                      {killMethodMapping[profileData.scheme.wrongKillingMethod]}
                    </ProfileValue>
                  </FormLine>
                  <FormLine>
                    <FormLabel>超时时间</FormLabel>
                    <ProfileValue>{profileData.scheme.seconds}</ProfileValue>
                  </FormLine>
                  <FormLine>
                    <FormLabel>提及文本</FormLabel>
                    <ProfileValue>
                      {mentionTextMapping[profileData.scheme.mentionText]}
                    </ProfileValue>
                  </FormLine>
                </div>
                <p tw="text-gray-600 text-sm tracking-wide mt-8">
                  注意：验证方案的系统默认值可能会被机器人拥有者随时维护性修改，所以上述默认值只能表示此刻的数据。如有需要，请自行定制适合本群的方案。
                </p>
              </main>
            ) : (
              <PageLoading />
            )}
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
