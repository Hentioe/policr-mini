import React, { useEffect, useState, useCallback } from "react";
import useSWR from "swr";
import { useSelector, useDispatch } from "react-redux";
import Select from "react-select";
import tw, { styled } from "twin.macro";
import Switch from "react-switch";

import { loadSelected } from "../slices/chats";
import { shown as readonlyShown } from "../slices/readonly";
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

const ProfileField = styled.div`
  ${tw`flex items-center mt-4`}
`;

const ProfileFieldLabel = styled.label`
  ${tw`w-4/12 text-gray-700`}
`;

const ProfileFieldValue = styled.div`
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

const defaultModeOption = { value: 5, label: "系统默认" };
const modeOptions = [
  { value: 0, label: "图片验证" },
  { value: 1, label: "定制验证（自定义）" },
  { value: 2, label: "算术验证" },
  { value: 3, label: "主动验证" },
  { value: 4, label: "网格验证（推荐）" },
  defaultModeOption,
];
const modeMapping = {
  image: 0,
  custom: 1,
  arithmetic: 2,
  initiative: 3,
  grid: 4,
};

const customSecondsOption = { value: "custom", label: "自定义" };
const defaultSecondsOption = { value: "default", label: "系统默认" };
const secondsOptions = [
  { value: 45, label: "生成：超短" },
  { value: 75, label: "生成：较短" },
  { value: 150, label: "生成：一般" },
  { value: 300, label: "生成：较长" },
  defaultSecondsOption,
  customSecondsOption,
];

const defaultKillingMethodOption = { value: null, label: "系统默认" };
const killingMethodOptions = [
  { value: 1, label: "踢出（封禁再延时解禁）" },
  { value: 0, label: "封禁" },
  defaultKillingMethodOption,
];

const customDelayUnabnSecsOption = { value: "custom", label: "自定义" };
const defaultDelayUnbanSecsOption = { value: "default", label: "系统默认" };
const delayUnabnSecsOptions = [
  { value: 60 * 5, label: "生成：5 分钟" },
  { value: 60 * 15, label: "生成：15 分钟" },
  { value: 3600 * 1, label: "生成：1 小时" },
  { value: 3600 * 3, label: "生成：3 小时" },
  { value: 3600 * 5, label: "生成：5 小时" },
  defaultSecondsOption,
  customSecondsOption,
];

const defaultMentionTextOption = { value: null, label: "系统默认" };
const mentionTextOptions = [
  { value: 0, label: "用户 ID" },
  { value: 1, label: "用户全名" },
  { value: 2, label: "马赛克全名" },
  defaultMentionTextOption,
];

const defaultImageAnswersCountOption = { value: null, label: "系统默认" };
const imageAnswersCountOptions = [
  { value: 3, label: "3" },
  { value: 4, label: "4" },
  { value: 5, label: "5" },
  defaultImageAnswersCountOption,
];

const modeValueMapping = {
  image: "图片验证",
  custom: "定制验证（自定义）",
  arithmetic: "算数验证",
  initiative: "主动验证",
  grid: "网格验证",
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
  delayUnbanSecs,
  mentionText,
  imageAnswersCount,
  serviceMessageCleanup,
}) => {
  const endpoint = `/admin/api/chats/${chatId}/scheme`;
  let body = null;
  if (verificationMode === defaultModeOption.value) verificationMode = null;
  if (seconds == "") seconds = null;
  if (delayUnbanSecs == "") delayUnbanSecs = null;

  body = {
    verification_mode: verificationMode,
    seconds: seconds,
    timeout_killing_method: timeoutKillingMethod,
    wrong_killing_method: wrongKillingMethod,
    delay_unban_secs: delayUnbanSecs,
    mention_text: mentionText,
    image_answers_count: imageAnswersCount,
    service_message_cleanup: serviceMessageCleanup,
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

  const { data: profileData, error: _profileError } =
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
  const [editingDelayUnbanSecsOption, setEditingDelayUnbanSecsOption] =
    useState(defaultDelayUnbanSecsOption);
  const [editingDelayUnbanSecs, setEditingDelayUnbanSecs] = useState(0);
  const [editingImageAnswersCountOption, setEditingImageAnswersCountOption] =
    useState(null);
  const [editingJoinedCleared, setEditingJoinedCleared] = useState(false);
  const [editingLeftedCleared, setEditingLeftedCleared] = useState(false);
  const [
    editingServiceMessageCleanupDefaulted,
    setEditingServiceMessageCleanupDefaulted,
  ] = useState(false);

  const rebind = useCallback(() => {
    setModeValue(getModeValueFromData());

    if (data && data.scheme) {
      const {
        seconds,
        timeoutKillingMethod,
        wrongKillingMethod,
        delayUnbanSecs,
        mentionText,
        imageAnswersCount,
        serviceMessageCleanup,
      } = data.scheme;

      setEditingSeconds(seconds || "");
      if (seconds == null) setEditingSecondsOption(defaultSecondsOption);
      else setEditingSecondsOption(customSecondsOption);

      if (timeoutKillingMethod == null)
        setEditingTimeoutKillingMethodOption(defaultKillingMethodOption);
      else if (timeoutKillingMethod == "kick")
        setEditingTimeoutKillingMethodOption(killingMethodOptions[0]);
      else if (timeoutKillingMethod == "ban")
        setEditingTimeoutKillingMethodOption(killingMethodOptions[1]);

      if (delayUnbanSecs == null)
        setEditingDelayUnbanSecsOption(defaultSecondsOption);
      else setEditingDelayUnbanSecsOption(customDelayUnabnSecsOption);
      setEditingDelayUnbanSecs(delayUnbanSecs || "");

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

      if (imageAnswersCount == null)
        setEditingImageAnswersCountOption(defaultImageAnswersCountOption);
      else if (imageAnswersCount === 3)
        setEditingImageAnswersCountOption(imageAnswersCountOptions[0]);
      else if (imageAnswersCount === 4)
        setEditingImageAnswersCountOption(imageAnswersCountOptions[1]);
      else if (imageAnswersCount === 5)
        setEditingImageAnswersCountOption(imageAnswersCountOptions[2]);

      // 绑定服务消息清理。注意：必须保证默认状态都是 false。
      if (serviceMessageCleanup != null) {
        setEditingJoinedCleared(serviceMessageCleanup.includes("joined"));
        setEditingLeftedCleared(serviceMessageCleanup.includes("lefted"));
        setEditingServiceMessageCleanupDefaulted(false);
      } else {
        setEditingJoinedCleared(false);
        setEditingLeftedCleared(false);
        setEditingServiceMessageCleanupDefaulted(true);
      }
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
    setEditingSeconds(value);
  };

  const handleEditingTimeoutKillingMethodSelectChange = (option) => {
    setIsEdited(true);
    setEditingTimeoutKillingMethodOption(option);
  };

  const handleEditingWrongKillingMethodSelectChange = (option) => {
    setIsEdited(true);
    setEditingWrongKillingMethodOption(option);
  };

  const handleEditingDelayUnbanSecsSelectChange = (option) => {
    setIsEdited(true);
    setEditingDelayUnbanSecsOption(option);

    if (!isNaN(option.value)) {
      setEditingDelayUnbanSecs(option.value);
    } else {
      setEditingDelayUnbanSecs("");
    }
  };

  const handleEditingDelayUnbanSecsChange = (e) => {
    setIsEdited(true);
    const value = e.target.value;

    if (!delayUnabnSecsOptions.map(({ value }) => value).includes(value)) {
      setEditingDelayUnbanSecsOption(customDelayUnabnSecsOption);
    }
    setEditingDelayUnbanSecs(value);
  };

  const handleEditingMentionTextOptionChange = (option) => {
    setIsEdited(true);
    setEditingMentionTextOption(option);
  };

  const handleSaveCancel = useCallback(() => {
    setIsEdited(false);
    rebind();
  });

  const handleEditingImageAnswersCountOptionChange = (option) => {
    setIsEdited(true);
    setEditingImageAnswersCountOption(option);
  };

  const handleJoinedCleanupChange = (checked) => {
    setIsEdited(true);
    setEditingJoinedCleared(checked);
  };

  const handleLeftedCleanupChange = (checked) => {
    setIsEdited(true);
    setEditingLeftedCleared(checked);
  };

  const handleServiceMessageCleanupDefaultedChange = (checked) => {
    setIsEdited(true);
    setEditingServiceMessageCleanupDefaulted(checked);
  };

  const handleSaveScheme = useCallback(async () => {
    let serviceMessageCleanup = null;
    if (!editingServiceMessageCleanupDefaulted) {
      serviceMessageCleanup = [];
      if (editingJoinedCleared) serviceMessageCleanup.push(0);
      if (editingLeftedCleared) serviceMessageCleanup.push(1);
    }

    const result = await saveScheme({
      id: data.scheme ? data.scheme.id : -1,
      chatId: chatsState.selected,
      verificationMode: modeValue,
      seconds: editingSeconds,
      timeoutKillingMethod: editingTimeoutKillingMethodOption.value,
      wrongKillingMethod: editingWrongKillingMethodOption.value,
      delayUnbanSecs: editingDelayUnbanSecs,
      mentionText: editingMentionTextOption.value,
      imageAnswersCount: editingImageAnswersCountOption.value,
      serviceMessageCleanup: serviceMessageCleanup,
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
    editingDelayUnbanSecs,
    editingMentionTextOption,
    editingImageAnswersCountOption,
    editingJoinedCleared,
    editingLeftedCleared,
    editingServiceMessageCleanupDefaulted,
  ]);

  const isLoaded = () => !error && chatsState.isLoaded && data && !data.errors;

  let title = "方案定制";
  if (isLoaded()) title += ` / ${data.chat.title}`;

  useEffect(() => {
    // 绑定数据到 UI。
    rebind();
  }, [data]);

  useEffect(() => {
    // 初始化只读显示状态。
    dispatch(readonlyShown(false));
  }, []);

  useEffect(() => {
    if (data && data.errors) toastErrors(data.errors);
    if (isLoaded()) {
      dispatch(loadSelected(data.chat));
      dispatch(readonlyShown(!data.writable));
    }
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
                <ProfileField>
                  <ProfileFieldLabel>验证方式</ProfileFieldLabel>
                  <OwnSelect
                    options={modeOptions}
                    value={modeOptions[modeValue]}
                    onChange={handleModeSelectChange}
                    isSearchable={false}
                  />
                </ProfileField>
                <FromHint>
                  自定义问答需修改此处为「定制验证」才可生效，取消选择其它即可
                </FromHint>
                <ProfileField>
                  <ProfileFieldLabel>击杀方法（验证超时）</ProfileFieldLabel>
                  <OwnSelect
                    options={killingMethodOptions}
                    value={editingTimeoutKillingMethodOption}
                    onChange={handleEditingTimeoutKillingMethodSelectChange}
                    isSearchable={false}
                  />
                </ProfileField>
                <FromHint>针对验证结果为「超时」的用户采取的措施</FromHint>
                <ProfileField>
                  <ProfileFieldLabel>击杀方法（验证错误）</ProfileFieldLabel>
                  <OwnSelect
                    options={killingMethodOptions}
                    value={editingWrongKillingMethodOption}
                    onChange={handleEditingWrongKillingMethodSelectChange}
                    isSearchable={false}
                  />
                </ProfileField>
                <FromHint>针对验证结果为「错误」的用户采取的措施</FromHint>
                <ProfileField>
                  <ProfileFieldLabel>超时时间</ProfileFieldLabel>
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
                </ProfileField>
                <FromHint>单个用户的验证等待时间，单位：秒</FromHint>
                <ProfileField>
                  <ProfileFieldLabel>解封延时</ProfileFieldLabel>
                  <div tw="w-8/12 flex flex-1">
                    <div tw="pr-2">
                      <Select
                        styles={{
                          control: (provided) => ({
                            ...provided,
                            width: 200,
                          }),
                        }}
                        options={delayUnabnSecsOptions}
                        onChange={handleEditingDelayUnbanSecsSelectChange}
                        isSearchable={false}
                        value={editingDelayUnbanSecsOption}
                      />
                    </div>

                    <div tw="flex-1">
                      <FormInput
                        type="number"
                        tw="w-full text-center"
                        value={editingDelayUnbanSecs}
                        onChange={handleEditingDelayUnbanSecsChange}
                        placeholder={
                          editingDelayUnbanSecsOption.value == "default"
                            ? "系统默认值"
                            : "在此填入秒数"
                        }
                      />
                    </div>
                  </div>
                </ProfileField>
                <FromHint>封禁再延时解封的延迟时长，单位：秒</FromHint>
                <ProfileField>
                  <ProfileFieldLabel>提及文本</ProfileFieldLabel>
                  <OwnSelect
                    options={mentionTextOptions}
                    value={editingMentionTextOption}
                    onChange={handleEditingMentionTextOptionChange}
                    isSearchable={false}
                  />
                </ProfileField>
                <FromHint>
                  提及验证用户时显示的内容，马赛克指用符号遮挡部分文字
                </FromHint>
                <ProfileField>
                  <ProfileFieldLabel>答案个数（图片验证）</ProfileFieldLabel>
                  <OwnSelect
                    options={imageAnswersCountOptions}
                    value={editingImageAnswersCountOption}
                    onChange={handleEditingImageAnswersCountOptionChange}
                    isSearchable={false}
                  />
                </ProfileField>
                <FromHint>
                  图片验证时生成的答案个数，此数字不提供自定义
                </FromHint>
                <ProfileField>
                  <ProfileFieldLabel>服务消息清理</ProfileFieldLabel>
                  <div tw="flex flex-1">
                    {!editingServiceMessageCleanupDefaulted && (
                      <>
                        <div tw="w-4/12 flex items-center">
                          <label tw="mr-2 text-gray-700">加入群组</label>
                          <Switch
                            height={14}
                            width={30}
                            checked={editingJoinedCleared}
                            checkedIcon={false}
                            uncheckedIcon={false}
                            onChange={handleJoinedCleanupChange}
                          />
                        </div>
                        <div tw="w-4/12 flex items-center">
                          <label tw="mr-2 text-gray-700">退出群组</label>
                          <Switch
                            height={14}
                            width={30}
                            checked={editingLeftedCleared}
                            checkedIcon={false}
                            uncheckedIcon={false}
                            onChange={handleLeftedCleanupChange}
                          />
                        </div>
                      </>
                    )}
                    <div tw="w-4/12 flex items-center">
                      <label tw="mr-2 text-gray-700">系统默认</label>
                      <Switch
                        height={14}
                        width={30}
                        checked={editingServiceMessageCleanupDefaulted}
                        checkedIcon={false}
                        uncheckedIcon={false}
                        onChange={handleServiceMessageCleanupDefaultedChange}
                      />
                    </div>
                  </div>
                </ProfileField>
                <FromHint>清理用户加入或退出群组时产生的系统消息</FromHint>
              </form>
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

          <PageSection>
            <PageSectionHeader>
              <PageSectionTitle>系统默认值</PageSectionTitle>
            </PageSectionHeader>
            {profileData ? (
              <main>
                <div>
                  <ProfileField>
                    <ProfileFieldLabel>验证方式</ProfileFieldLabel>
                    <ProfileFieldValue>
                      {modeValueMapping[profileData.scheme.verificationMode]}
                    </ProfileFieldValue>
                  </ProfileField>
                  <ProfileField>
                    <ProfileFieldLabel>击杀方法（验证超时）</ProfileFieldLabel>
                    <ProfileFieldValue>
                      {
                        killMethodMapping[
                          profileData.scheme.timeoutKillingMethod
                        ]
                      }
                    </ProfileFieldValue>
                  </ProfileField>
                  <ProfileField>
                    <ProfileFieldLabel>击杀方法（验证错误）</ProfileFieldLabel>
                    <ProfileFieldValue>
                      {killMethodMapping[profileData.scheme.wrongKillingMethod]}
                    </ProfileFieldValue>
                  </ProfileField>
                  <ProfileField>
                    <ProfileFieldLabel>超时时间</ProfileFieldLabel>
                    <ProfileFieldValue>
                      {profileData.scheme.seconds}
                    </ProfileFieldValue>
                  </ProfileField>
                  <ProfileField>
                    <ProfileFieldLabel>解封延时</ProfileFieldLabel>
                    <ProfileFieldValue>
                      {profileData.scheme.delayUnbanSecs}
                    </ProfileFieldValue>
                  </ProfileField>
                  <ProfileField>
                    <ProfileFieldLabel>提及文本</ProfileFieldLabel>
                    <ProfileFieldValue>
                      {mentionTextMapping[profileData.scheme.mentionText]}
                    </ProfileFieldValue>
                  </ProfileField>
                  <ProfileField>
                    <ProfileFieldLabel>答案个数（图片验证）</ProfileFieldLabel>
                    <ProfileFieldValue>
                      {profileData.scheme.imageAnswersCount}
                    </ProfileFieldValue>
                  </ProfileField>
                  <ProfileField>
                    <ProfileFieldLabel>服务消息清理</ProfileFieldLabel>
                    <ProfileFieldValue tw="flex">
                      <div tw="w-4/12">
                        <label>加入群组</label>
                        <span tw="ml-1">
                          {(
                            profileData.scheme.serviceMessageCleanup || []
                          ).includes("joined")
                            ? "✓"
                            : "✕"}
                        </span>
                      </div>
                      <div tw="w-4/12">
                        <label>退出群组</label>
                        <span tw="ml-1">
                          {(
                            profileData.scheme.serviceMessageCleanup || []
                          ).includes("lefted")
                            ? "✓"
                            : "✕"}
                        </span>
                      </div>
                    </ProfileFieldValue>
                  </ProfileField>
                </div>
                <p tw="text-gray-600 text-sm tracking-wide mt-8">
                  注意：上述默认值只能表示此刻的数据，因为系统默认值可能会被机器人拥有者随时维护性修改。如有需要，请自行定制适合本群的方案。
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
