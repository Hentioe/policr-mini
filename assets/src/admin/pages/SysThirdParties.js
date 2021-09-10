import React, { useState, useCallback, useEffect } from "react";
import useSWR from "swr";
import tw, { styled } from "twin.macro";
import fetch from "unfetch";
import { useLocation } from "react-router-dom";
import { useDispatch } from "react-redux";

import { shown as readonlyShown } from "../slices/readonly";
import {
  PageHeader,
  PageBody,
  PageSection,
  PageLoading,
  PageReLoading,
  LabelledButton,
  ActionButton,
  FormInput,
} from "../components";
import { Table, Thead, Tr, Th, Tbody, Td } from "../components/Tables";
import { camelizeJson, toastErrors } from "../helper";

const FormSection = styled.div`
  ${tw`flex flex-wrap items-center py-4`}
`;
const FormLable = styled.label`
  ${tw`w-full mb-2 lg:mb-0 lg:w-3/12`}
`;

const Title = styled.span`
  color: #2f3235;
  ${tw`text-lg`}
`;

const Paragraph = styled.p`
  ${tw`m-0`}
`;

const HintParagraph = styled(Paragraph)`
  ${tw`py-5 text-center text-lg text-gray-400 font-bold`}
`;

const EDITING_CHECK = {
  VALID: 1,
  NO_EDINTINT: 0,
  EMPTY_NAME: -1,
  MISSING_CORRECT: -2,
  CONTENT_WRONG: -3,
};

const initialEditingName = "";
const initialEditingId = 0;

const makeEndpoint = () => `/admin/api/third_parties`;

const saveThirdParty = async ({
  id,
  name,
  botUsername,
  homepage,
  description,
  hardware,
  runningDays,
  isForked,
}) => {
  let endpoint = "/admin/api/third_parties";
  let method = "POST";
  if (id) {
    endpoint = `/admin/api/third_parties/${id}`;
    method = "PUT";
  }
  return fetch(endpoint, {
    method: method,
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      name: name,
      bot_username: botUsername,
      homepage: homepage,
      description: description,
      hardware: hardware,
      running_days: runningDays,
      is_forked: isForked,
    }),
  }).then((r) => camelizeJson(r));
};

const deleteThirdParty = async (id) => {
  const endpoint = `/admin/api/third_parties/${id}`;
  const method = "DELETE";
  return fetch(endpoint, {
    method: method,
  }).then((r) => camelizeJson(r));
};

export default () => {
  const location = useLocation();
  const dispatch = useDispatch();

  const { data, mutate, error } = useSWR(makeEndpoint());
  const [isEditing, setIsEditing] = useState(false);
  const [editingId, setEditingId] = useState(initialEditingId);
  const [editingName, setEditingName] = useState(initialEditingName);
  const [editingBotUsername, setEditingBotUsername] = useState("");
  const [editingHomepage, setEditingHomepage] = useState("");
  const [editingDescription, setEditingDescription] = useState("");
  const [editingHardware, setEditingHardware] = useState("");
  const [editingRunningDays, setEditingRunningDays] = useState(1);
  const [editingIsForked, setEditingIsForked] = useState(false);

  const handleIsEditing = () => setIsEditing(!isEditing);
  const initEditingContent = () => {
    setIsEditing(false);

    setEditingId(initialEditingId);
    setEditingName(initialEditingName);
    setEditingBotUsername("");
    setEditingHomepage("");
    setEditingDescription("");
    setEditingHardware("");
    setEditingRunningDays(1);
    setEditingIsForked(false);
  };
  const handleCancelEditing = () => initEditingContent();
  const handleEditingNameChange = (e) => setEditingName(e.target.value.trim());
  const handleEditingBotUsernameChange = (e) =>
    setEditingBotUsername(e.target.value.trim());
  const handleEditingHomepageChange = (e) =>
    setEditingHomepage(e.target.value.trim());
  const handleEditingDescriptionChange = (e) =>
    setEditingDescription(e.target.value);
  const handleEditingHardwareChange = (e) =>
    setEditingHardware(e.target.value.trim());
  const handleEditingRunningDaysChange = (e) =>
    setEditingRunningDays(e.target.value);
  // const handleEditingIsForkedChange = (e) =>
  //   setEditingIsForked(!e.target.checked);

  const isLoaded = () => !error && data && !data.errors;

  const checkEditintValid = useCallback(() => {
    if (!isEditing) return EDITING_CHECK.NO_EDINTINT;
    if (editingName.trim() == "") return EDITING_CHECK.EMPTY_NAME;

    return EDITING_CHECK.VALID;
  }, [isEditing, editingName]);

  const handleSaveClick = useCallback(
    async (e) => {
      e.preventDefault();

      const result = await saveThirdParty({
        id: editingId,
        name: editingName,
        botUsername: editingBotUsername,
        homepage: editingHomepage,
        description: editingDescription,
        hardware: editingHardware,
        runningDays: editingRunningDays,
        isForked: editingIsForked,
      });

      if (result.errors) toastErrors(result.errors);
      else {
        // 保存成功
        mutate();
        // 初始化编辑内容
        initEditingContent();
      }
    },
    [
      editingId,
      editingName,
      editingBotUsername,
      editingHomepage,
      editingDescription,
      editingHardware,
      editingRunningDays,
      editingIsForked,
    ]
  );

  const handleDeleteClick = useCallback(
    (id) => {
      deleteThirdParty(id).then((result) => {
        if (result.errors) toastErrors(result.errors);
        else mutate();
      });
    },
    [data]
  );

  const handleEditClick = useCallback(
    (index) => {
      const thirdParty = data.thirdParties[index];

      setIsEditing(true);
      setEditingId(thirdParty.id);
      setEditingName(thirdParty.name);
      setEditingBotUsername(thirdParty.botUsername);
      setEditingHomepage(thirdParty.homepage);
      setEditingDescription(thirdParty.description);
      setEditingHardware(thirdParty.hardware);
      setEditingRunningDays(thirdParty.runningDays);
      setEditingIsForked(thirdParty.isForked);
    },
    [data]
  );

  useEffect(() => {
    // 初始化编辑内容
    initEditingContent();
    // 初始化只读显示状态。
    dispatch(readonlyShown(false));
  }, [location]);

  const editingCheckResult = checkEditintValid();

  let title = "第三方实例";

  useEffect(() => {
    if (data && data.errors) toastErrors(data.errors);
  }, [data]);

  return (
    <>
      <PageHeader title={title} />
      {isLoaded() ? (
        <PageBody>
          <PageSection>
            <header>
              <Title>实例列表</Title>
            </header>
            <main>
              {data.thirdParties.length > 0 ? (
                <div tw="mt-4">
                  <ActionButton onClick={handleIsEditing}>
                    + 添加新实例
                  </ActionButton>
                  <Table tw="shadow rounded">
                    <Thead>
                      <Tr>
                        <Th tw="w-2/12 pr-0">名称</Th>
                        <Th tw="w-5/12 text-center px-0">主页</Th>
                        <Th tw="w-3/12 text-center">运行天数</Th>
                        <Th tw="w-2/12 text-right">操作</Th>
                      </Tr>
                    </Thead>
                    <Tbody>
                      {data.thirdParties.map((thirdParty, index) => (
                        <Tr key={thirdParty.id}>
                          <Td tw="break-all pr-0">{thirdParty.name}</Td>
                          <Td tw="text-center px-0">
                            <a
                              tw="text-gray-700"
                              href={thirdParty.homepage}
                              target="_blank"
                            >
                              {thirdParty.homepage}
                            </a>
                          </Td>
                          <Td tw="text-center">{thirdParty.runningDays}</Td>
                          <Td tw="text-right">
                            <ActionButton
                              tw="mr-1"
                              onClick={() => handleEditClick(index)}
                            >
                              编辑
                            </ActionButton>
                            <ActionButton
                              onClick={() => handleDeleteClick(thirdParty.id)}
                            >
                              删除
                            </ActionButton>
                          </Td>
                        </Tr>
                      ))}
                    </Tbody>
                  </Table>
                </div>
              ) : (
                <HintParagraph>
                  当前未添加任何实例，
                  <span
                    tw="underline cursor-pointer text-blue-300"
                    onClick={handleIsEditing}
                  >
                    点此添加
                  </span>
                  。
                </HintParagraph>
              )}
            </main>
          </PageSection>
          <PageSection>
            <header>
              <Title>当前编辑的实例</Title>
            </header>
            <main>
              {isEditing ? (
                <form>
                  <FormSection>
                    <FormLable>名称</FormLable>
                    <FormInput
                      tw="w-full lg:w-9/12"
                      value={editingName}
                      onChange={handleEditingNameChange}
                    />
                  </FormSection>
                  <FormSection>
                    <FormLable>机器人用户名</FormLable>
                    <FormInput
                      tw="w-full lg:w-9/12"
                      value={editingBotUsername}
                      onChange={handleEditingBotUsernameChange}
                    />
                  </FormSection>
                  <FormSection>
                    <FormLable>主页链接</FormLable>
                    <FormInput
                      tw="w-full lg:w-9/12"
                      value={editingHomepage}
                      onChange={handleEditingHomepageChange}
                    />
                  </FormSection>
                  <FormSection>
                    <FormLable>描述</FormLable>
                    <FormInput
                      tw="w-full lg:w-9/12"
                      value={editingDescription}
                      onChange={handleEditingDescriptionChange}
                    />
                  </FormSection>
                  <FormSection>
                    <FormLable>硬件字符串</FormLable>
                    <FormInput
                      tw="w-full lg:w-9/12"
                      value={editingHardware}
                      onChange={handleEditingHardwareChange}
                    />
                  </FormSection>
                  <FormSection>
                    <FormLable>运行天数</FormLable>
                    <FormInput
                      type="number"
                      tw="w-full lg:w-9/12"
                      value={editingRunningDays}
                      onChange={handleEditingRunningDaysChange}
                    />
                  </FormSection>
                  <div tw="flex mt-2">
                    <div tw="flex-1 pr-10">
                      <LabelledButton
                        label="cancel"
                        onClick={handleCancelEditing}
                      >
                        取消
                      </LabelledButton>
                    </div>
                    <div tw="flex-1 pl-10">
                      <LabelledButton
                        label="ok"
                        disabled={editingCheckResult !== EDITING_CHECK.VALID}
                        onClick={handleSaveClick}
                      >
                        保存
                      </LabelledButton>
                    </div>
                  </div>
                </form>
              ) : (
                <HintParagraph>请选择或新增一个实例。</HintParagraph>
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
