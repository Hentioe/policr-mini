import React, { useEffect, useState, useCallback, useRef } from "react";
import useSWR from "swr";
import { useDispatch } from "react-redux";
import Select from "react-select";
import tw, { styled } from "twin.macro";
import { formatBytes } from "bytes-formatter";
import Switch from "react-switch";

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

const FormLine = styled.div`
  ${tw`flex items-center mt-2`}
`;

const FormLabel = styled.label`
  ${tw`w-4/12 text-gray-700`}
`;

const AlbumsLine = styled.div`
  ${tw`flex mt-2`}
`;

const AlbumsLabel = styled.label`
  ${tw`w-4/12 text-gray-700`}
`;

const AlbumsValue = styled.label`
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

import { camelizeJson, toastErrors, toastMessage } from "../helper";
import ActionButton from "../components/ActionButton";

const modeOptions = [
  { value: 0, label: "图片验证" },
  { value: 1, label: "定制验证（自定义）" },
  { value: 2, label: "算术验证" },
  { value: 3, label: "主动验证" },
  { value: 4, label: "网格验证（推荐）" },
  { value: 5, label: "经典验证（传统验证码）" },
];
const modeMapping = {
  image: 0,
  custom: 1,
  arithmetic: 2,
  initiative: 3,
  grid: 4,
  classic: 5,
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

const imageAnswersCountOptions = [
  { value: 3, label: "3" },
  { value: 4, label: "4" },
  { value: 5, label: "5" },
];

const saveScheme = async ({
  verificationMode,
  seconds,
  timeoutKillingMethod,
  wrongKillingMethod,
  delayUnbanSecs,
  mentionText,
  imageAnswersCount,
  serviceMessageCleanup,
}) => {
  const endpoint = `/admin/api/profile/scheme`;

  const body = {
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

const deleteUploadedAlbums = async () => {
  const endpoint = `/admin/api/profile/temp_albums`;

  return fetch(endpoint, {
    method: "DELETE",
  }).then((r) => camelizeJson(r));
};

const updateAlbums = async () => {
  const endpoint = `/admin/api/profile/albums`;

  return fetch(endpoint, {
    method: "PUT",
  }).then((r) => camelizeJson(r));
};

const uploadAlbums = async (fd) => {
  const endpoint = `/admin/api/profile/temp_albums`;

  return fetch(endpoint, {
    method: "POST",
    body: fd,
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

  const [selectedFile, setSelectedFile] = useState(null);

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
  const [editingDelayUnbanSecs, setEditingDelayUnbanSecs] = useState(0);
  const [editingImageAnswersCountOption, setEditingImageAnswersCountOption] =
    useState(null);
  const [editingJoinedCleared, setEditingJoinedCleared] = useState(false);
  const [editingLeftedCleared, setEditingLeftedCleared] = useState(false);

  const fileInputRef = useRef(null);

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

      if (timeoutKillingMethod == "kick")
        setEditingTimeoutKillingMethodOption(killingMethodOptions[0]);
      else if (timeoutKillingMethod == "ban")
        setEditingTimeoutKillingMethodOption(killingMethodOptions[1]);

      if (wrongKillingMethod == "kick")
        setEditingWrongKillingMethodOption(killingMethodOptions[0]);
      else if (wrongKillingMethod == "ban")
        setEditingWrongKillingMethodOption(killingMethodOptions[1]);

      setEditingDelayUnbanSecs(delayUnbanSecs || "");

      if (mentionText == "user_id")
        setEditingMentionTextOption(mentionTextOptions[0]);
      else if (mentionText == "full_name")
        setEditingMentionTextOption(mentionTextOptions[1]);
      else if (mentionText == "mosaic_full_name")
        setEditingMentionTextOption(mentionTextOptions[2]);

      if (imageAnswersCount === 3)
        setEditingImageAnswersCountOption(imageAnswersCountOptions[0]);
      else if (imageAnswersCount === 4)
        setEditingImageAnswersCountOption(imageAnswersCountOptions[1]);
      else if (imageAnswersCount === 5)
        setEditingImageAnswersCountOption(imageAnswersCountOptions[2]);

      // 绑定服务消息清理。注意：必须保证默认状态都是 false。
      if (serviceMessageCleanup != null) {
        setEditingJoinedCleared(serviceMessageCleanup.includes("joined"));
        setEditingLeftedCleared(serviceMessageCleanup.includes("lefted"));
      } else {
        setEditingJoinedCleared(false);
        setEditingLeftedCleared(false);
      }
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

  const handleEditingDelayUnbanSecsChange = (e) => {
    setIsEdited(true);
    setEditingDelayUnbanSecs(e.target.value);
  };

  const handleEditingMentionTextOptionChange = (option) => {
    setIsEdited(true);
    setEditingMentionTextOption(option);
  };

  const handleEditingImageAnswersCountOptionChange = (option) => {
    setIsEdited(true);
    setEditingImageAnswersCountOption(option);
  };

  const handleSaveCancel = useCallback(() => {
    setIsEdited(false);
    rebind();
  });

  const handleJoinedCleanupChange = (checked) => {
    setIsEdited(true);
    setEditingJoinedCleared(checked);
  };

  const handleLeftedCleanupChange = (checked) => {
    setIsEdited(true);
    setEditingLeftedCleared(checked);
  };

  const handleSaveScheme = useCallback(async () => {
    let serviceMessageCleanup = [];
    if (editingJoinedCleared) serviceMessageCleanup.push(0);
    if (editingLeftedCleared) serviceMessageCleanup.push(1);

    const result = await saveScheme({
      id: data.scheme ? data.scheme.id : -1,
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
  ]);

  const handleDeleteUploaded = async () => {
    const result = await deleteUploadedAlbums();

    if (result.errors) {
      toastErrors(result.errors);
      return;
    }

    mutate();
  };

  const handleDeployAlbums = async () => {
    const result = await updateAlbums();

    if (result.errors) {
      toastErrors(result.errors);
      return;
    } else {
      toastMessage("更新成功");
      mutate();
    }
  };

  const fileInputChange = (e) => {
    setSelectedFile(e.target.files[0]);
  };

  const handleSelectLocalFile = () => fileInputRef.current.click();

  const handleUpload = useCallback(async () => {
    const fd = new FormData();
    fd.append("archive", selectedFile);

    const result = await uploadAlbums(fd);

    if (result.errors) {
      toastErrors(result.errors);
      return;
    } else {
      toastMessage("上传成功，请确认更新");
      mutate();
    }
  }, [selectedFile]);

  useEffect(() => {
    // 初始化文件输入事件
    const element = fileInputRef.current;

    if (element) {
      element.addEventListener("change", fileInputChange, false);

      return () => element.removeEventListener("change", fileInputChange);
    }
  }, [data, error]);

  const isLoaded = () => !error && data && !data.errors;

  let title = "全局属性";

  useEffect(() => {
    // 绑定数据到 UI。
    rebind();
  }, [data]);

  useEffect(() => {
    // 初始化只读显示状态。
    dispatch(readonlyShown(false));
  }, [location]);

  useEffect(() => {
    if (data && data.errors) toastErrors(data.errors);
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
                    tw="w-8/12"
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
                <FormLine>
                  <FormLabel>解封延时</FormLabel>
                  <FormInput
                    type="number"
                    tw="w-8/12"
                    value={editingDelayUnbanSecs}
                    onChange={handleEditingDelayUnbanSecsChange}
                    placeholder="在此填入秒数"
                  />
                </FormLine>
                <FromHint>封禁再延时解封的延迟时长，单位：秒</FromHint>
                <FormLine>
                  <FormLabel>答案个数（图片验证）</FormLabel>
                  <OwnSelect
                    options={imageAnswersCountOptions}
                    value={editingImageAnswersCountOption}
                    onChange={handleEditingImageAnswersCountOptionChange}
                    isSearchable={false}
                  />
                </FormLine>
                <FromHint>
                  图片验证时生成的答案个数，此数字不提供自定义
                </FromHint>
                <FormLine>
                  <FormLabel>服务消息清理</FormLabel>
                  <div tw="flex flex-1">
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
                  </div>
                </FormLine>
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
              <PageSectionTitle>更新图片验证的资源</PageSectionTitle>
            </PageSectionHeader>
            <main>
              <div>
                <p tw="text-gray-800 font-bold">当前资源</p>
                {data.deployedInfo.manifest ? (
                  <div>
                    <AlbumsLine>
                      <AlbumsLabel>版本</AlbumsLabel>
                      <AlbumsValue>{data.deployedInfo.manifest.version}</AlbumsValue>
                    </AlbumsLine>
                    <AlbumsLine>
                      <AlbumsLabel>生成日期</AlbumsLabel>
                      <AlbumsValue>{data.deployedInfo.manifest.datetime}</AlbumsValue>
                    </AlbumsLine>
                    <AlbumsLine>
                      <AlbumsLabel>图集总数</AlbumsLabel>
                      <AlbumsValue>{data.deployedInfo.manifest.albums.length}</AlbumsValue>
                    </AlbumsLine>
                    <AlbumsLine>
                      <AlbumsLabel>图片总数</AlbumsLabel>
                      <AlbumsValue>{data.deployedInfo.totalImages}</AlbumsValue>
                    </AlbumsLine>
                  </div>
                ) : (
                  <div>无</div>
                )}
              </div>
              <div>
                <p tw="text-gray-800 font-bold">
                  临时资源
                  {data.uploaded && (
                    <span tw="text-yellow-500">（待确认更新）</span>
                  )}
                </p>
                {data.uploaded ? (
                  <div>
                    <AlbumsLine>
                      <AlbumsLabel>版本</AlbumsLabel>
                      <AlbumsValue>{data.uploaded.manifest.version}</AlbumsValue>
                    </AlbumsLine>
                    <AlbumsLine>
                      <AlbumsLabel>生成日期</AlbumsLabel>
                      <AlbumsValue>{data.uploaded.manifest.datetime}</AlbumsValue>
                    </AlbumsLine>
                    <AlbumsLine>
                      <AlbumsLabel>图集总数</AlbumsLabel>
                      <AlbumsValue>{data.uploaded.manifest.albums.length}</AlbumsValue>
                    </AlbumsLine>
                    <AlbumsLine>
                      <AlbumsLabel>图片总数</AlbumsLabel>
                      <AlbumsValue>{data.uploaded.totalImages}</AlbumsValue>
                    </AlbumsLine>
                    <AlbumsLine>
                      <AlbumsLabel>操作</AlbumsLabel>
                      <AlbumsValue>
                        <ActionButton onClick={handleDeleteUploaded}>
                          删除此资源
                        </ActionButton>
                      </AlbumsValue>
                    </AlbumsLine>
                  </div>
                ) : (
                  <div>无</div>
                )}
              </div>
              {selectedFile && (
                <div>
                  <p tw="text-gray-800 font-bold">待上传</p>
                  <div tw="mt-2 flex items-center">
                    <span tw="w-4/12 text-gray-700">
                      {selectedFile.name} ({formatBytes(selectedFile.size)})
                    </span>
                    <ActionButton tw="ml-2" onClick={handleUpload}>
                      开始上传
                    </ActionButton>
                  </div>
                </div>
              )}
              <div tw="mt-4">
                {/* 隐藏的文件输入 */}
                <input
                  ref={fileInputRef}
                  type="file"
                  accept=".zip"
                  tw="hidden"
                />
                <div>
                  <LabelledButton label="ok" onClick={handleSelectLocalFile}>
                    {selectedFile && "重新"}选择资源包
                  </LabelledButton>
                </div>

                <div tw="mt-2">
                  <LabelledButton
                    label="cancel"
                    onClick={handleDeployAlbums}
                    disabled={data.uploaded == null}
                  >
                    确认更新
                  </LabelledButton>
                </div>
              </div>
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
