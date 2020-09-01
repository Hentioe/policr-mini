import React, { useState, useCallback, useEffect } from "react";
import useSWR from "swr";
import { useSelector } from "react-redux";
import tw, { styled } from "twin.macro";
import Select from "react-select";
import fetch from "unfetch";
import { useDispatch } from "react-redux";
import { useLocation, Link as RouteLink } from "react-router-dom";
import { parseISO, format as formatDateTime } from "date-fns";

import { loadSelected } from "../slices/chats";
import {
  PageHeader,
  PageBody,
  PageSection,
  PageLoading,
  PageReLoading,
  LabelledButton,
  ActionButton,
} from "../components";
import { Table, Thead, Tr, Th, Tbody, Td } from "../components/Tables";
import { updateInNewArray, camelizeJson, toastErrors } from "../helper";

const FormSection = styled.div`
  ${tw`flex flex-wrap items-center py-4`}
`;
const FormLable = styled.label`
  ${tw`w-full mb-2 lg:mb-0 lg:w-3/12`}
`;

const FormInput = styled.input.attrs({
  type: "text",
})`
  border: 0 solid #e2e8f0;
  border-color: hsl(0, 0%, 80%);
  ${tw`h-8 px-2 box-border rounded appearance-none border focus:outline-none focus:shadow-outline`};
`;

const kitTypeOptions = [
  { value: "Text", label: "文字提问" },
  { value: "Photo", label: "图片提问", isDisabled: true },
];

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

const InlineKeybordButton = styled.div`
  ${tw`shadow-sm bg-blue-400 text-white rounded-md px-4 py-2 text-sm mt-1 flex justify-center bg-opacity-75 cursor-pointer`}
`;

const EDITING_CHECK = {
  VALID: 1,
  NO_EDINTINT: 0,
  EMPTY_TITLE: -1,
  MISSING_CORRECT: -2,
};

const ROW = {
  RIGHT: 1,
  WRONG: 0,
};

const RIGHT_FLAG = { value: ROW.RIGHT, label: "正确" };
const WRONG_FLAG = { value: ROW.WRONG, label: "错误" };

const answerROWOptions = [RIGHT_FLAG, WRONG_FLAG];

const initialEditingTitle = "";
const initialEditingId = 0;
const initialAnswer = { row: answerROWOptions[1], text: "" };
const dateTimeFormat = "yyyy-MM-dd HH:mm:ss";

const makeEndpoint = (chat_id) => `/admin/api/chats/${chat_id}/customs`;

const saveCustomKit = async ({ id, chatId, title, answers }) => {
  let endpoint = "/admin/api/customs";
  let method = "POST";
  if (id) {
    endpoint = `/admin/api/customs/${id}`;
    method = "PUT";
  }
  return fetch(endpoint, {
    method: method,
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      chat_id: chatId,
      title: title,
      answers: answers,
    }),
  }).then((r) => camelizeJson(r));
};

const deleteCustomKit = async (id) => {
  const endpoint = `/admin/api/customs/${id}`;
  const method = "DELETE";
  return fetch(endpoint, {
    method: method,
  }).then((r) => camelizeJson(r));
};

export default () => {
  const chatsState = useSelector((state) => state.chats);
  const location = useLocation();
  const dispatch = useDispatch();

  const { data, mutate, error } = useSWR(
    chatsState && chatsState.isLoaded && chatsState.selected
      ? makeEndpoint(chatsState.selected)
      : null
  );
  const [isEditing, setIsEditing] = useState(false);
  const [editingId, setEditingId] = useState(initialEditingId);
  const [editingKitType, setEditingKitType] = useState(kitTypeOptions[0]);
  const [editintTitle, setEditingTitle] = useState(initialEditingTitle);
  const [answers, setAnswers] = useState([initialAnswer]);

  const handleIsEditing = () => setIsEditing(!isEditing);
  const handleKitTypeChange = (value) => setEditingKitType(value);
  const initEditingContent = () => {
    setIsEditing(false);
    setEditingTitle(initialEditingTitle);
    setEditingId(initialEditingId);
    setAnswers([initialAnswer]);
  };
  const handleCancelEditing = () => initEditingContent();
  const handleTitleChange = (e) => setEditingTitle(e.target.value.trim());
  const handleAnswerROWChange = useCallback(
    (value, index) => {
      const newAnswers = updateInNewArray(
        answers,
        { ...answers[index], row: value },
        index
      );

      setAnswers(newAnswers);
    },
    [answers]
  );

  const handleAnswerAddOrDelete = useCallback(
    (index) => {
      if (index == answers.length - 1) {
        setAnswers([...answers, initialAnswer]);
      } else {
        const newAnswers = [...answers];
        newAnswers[index] = undefined;
        setAnswers(newAnswers.filter((ans) => ans));
      }
    },
    [answers]
  );

  const handleAnswerTextChange = useCallback(
    (index, text) => {
      const newAnswers = updateInNewArray(
        answers,
        { ...answers[index], text: text },
        index
      );

      setAnswers(newAnswers);
    },
    [answers]
  );

  const isLoaded = () => !error && chatsState.isLoaded && data && !data.errors;

  const checkEditintValid = useCallback(() => {
    if (!isEditing) return EDITING_CHECK.NO_EDINTINT;
    if (editintTitle.trim() == "") return EDITING_CHECK.EMPTY_TITLE;
    const rightAnswers = answers
      .filter((ans) => ans.text.trim() != "")
      .filter((ans) => ans.row.value == ROW.RIGHT);
    if (rightAnswers.length == 0) return EDITING_CHECK.MISSING_CORRECT;

    return EDITING_CHECK.VALID;
  }, [isEditing, editintTitle, answers]);

  const handleSave = useCallback(
    (e) => {
      e.preventDefault();
      saveCustomKit({
        chatId: chatsState.selected,
        id: editingId,
        title: editintTitle,
        answers: answers.map(
          (ans) => `${ans.row.value ? "+" : "-"}${ans.text.trim()}`
        ),
      }).then((result) => {
        if (result.errors) toastErrors(result.errors);
        else {
          // 保存成功
          mutate();
          // 初始化编辑内容
          initEditingContent();
        }
      });
    },
    [editingId, editintTitle, answers]
  );

  const handleDelete = useCallback(
    (id) => {
      deleteCustomKit(id).then((result) => {
        if (result.errors) toastErrors(result.errors);
        else mutate();
      });
    },
    [data]
  );

  const handleEdit = useCallback(
    (index) => {
      const customKit = data.customKits[index];
      const editingId = customKit.id;
      const editingTitle = customKit.title;
      const answers = customKit.answers.map((ans) => {
        const row = ans.startsWith("+") ? RIGHT_FLAG : WRONG_FLAG;
        return { row: row, text: ans.substring(1, ans.length) };
      });

      setIsEditing(true);
      setEditingId(editingId);
      setEditingTitle(editingTitle);
      setAnswers(answers);
    },
    [data]
  );

  useEffect(() => {
    // 初始化编辑内容
    initEditingContent();
  }, [location]);

  const editingCheckResult = checkEditintValid();

  let title = "自定义";
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
            <header>
              <Title>已添加好的问题</Title>
            </header>
            <main>
              {data.customKits.length > 0 ? (
                <div tw="mt-4">
                  <ActionButton onClick={handleIsEditing}>
                    + 添加新问题
                  </ActionButton>
                  {!data.isEnabled && (
                    <RouteLink
                      tw="ml-2 text-gray-500"
                      to={`/admin/chats/${chatsState.selected}/scheme`}
                    >
                      切换到已定制的验证
                    </RouteLink>
                  )}
                  <Table tw="shadow rounded">
                    <Thead>
                      <Tr>
                        <Th tw="w-5/12 pr-0">标题</Th>
                        <Th tw="w-2/12 text-center px-0">答案个数</Th>
                        <Th tw="w-3/12">编辑于</Th>
                        <Th tw="w-2/12 text-right">操作</Th>
                      </Tr>
                    </Thead>
                    <Tbody>
                      {data.customKits.map((customKit, index) => (
                        <Tr key={customKit.id}>
                          <Td tw="break-all pr-0">{customKit.title}</Td>
                          <Td tw="text-center px-0">
                            {customKit.answers.length}
                          </Td>
                          <Td>
                            {formatDateTime(
                              parseISO(customKit.updatedAt),
                              dateTimeFormat
                            )}
                          </Td>
                          <Td tw="text-right">
                            <ActionButton
                              tw="mr-1"
                              onClick={() => handleEdit(index)}
                            >
                              编辑
                            </ActionButton>
                            <ActionButton
                              onClick={() => handleDelete(customKit.id)}
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
                  当前未添加任何问题，
                  <span tw="underline cursor-pointer" onClick={handleIsEditing}>
                    点此添加
                  </span>
                  。
                </HintParagraph>
              )}
            </main>
          </PageSection>
          <PageSection>
            <header>
              <Title>当前编辑的问题</Title>
            </header>
            <main>
              {isEditing ? (
                <form>
                  <FormSection>
                    <FormLable>类型</FormLable>
                    <div tw="w-full lg:w-9/12">
                      <Select
                        value={editingKitType}
                        options={kitTypeOptions}
                        onChange={handleKitTypeChange}
                        isSearchable={false}
                      />
                    </div>
                  </FormSection>
                  <FormSection>
                    <FormLable>标题</FormLable>
                    <FormInput
                      tw="w-full lg:w-9/12"
                      value={editintTitle}
                      onChange={handleTitleChange}
                    />
                  </FormSection>
                  {answers.map((answer, index) => (
                    <FormSection key={index}>
                      <FormLable>答案{index + 1}</FormLable>
                      <div tw="w-full lg:w-9/12 flex items-center">
                        <div css={{ width: "5.5rem" }}>
                          <Select
                            value={answer.row}
                            options={answerROWOptions}
                            onChange={(value) =>
                              handleAnswerROWChange(value, index)
                            }
                            isSearchable={false}
                          />
                        </div>
                        <div tw="flex-1 px-4 flex items-center">
                          <FormInput
                            tw="w-full inline"
                            value={answers[index].text}
                            onChange={(e) =>
                              handleAnswerTextChange(index, e.target.value)
                            }
                          />
                        </div>
                        <ActionButton
                          onClick={() => handleAnswerAddOrDelete(index)}
                        >
                          {answers.length - 1 == index ? "添加" : "删除"}
                        </ActionButton>
                      </div>
                    </FormSection>
                  ))}
                  <div tw="flex">
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
                        onClick={handleSave}
                      >
                        保存
                      </LabelledButton>
                    </div>
                  </div>
                </form>
              ) : (
                <HintParagraph>请选择或新增一个问题。</HintParagraph>
              )}
            </main>
          </PageSection>
          <PageSection>
            <header>
              <Title>正在预览的问题</Title>
            </header>
            <main>
              {editingCheckResult == EDITING_CHECK.NO_EDINTINT && (
                <HintParagraph>正在等待编辑</HintParagraph>
              )}
              {editingCheckResult == EDITING_CHECK.EMPTY_TITLE && (
                <HintParagraph>请输入问题标题</HintParagraph>
              )}
              {editingCheckResult == EDITING_CHECK.MISSING_CORRECT && (
                <HintParagraph>请添加至少一个正确答案</HintParagraph>
              )}
              {editingCheckResult == EDITING_CHECK.VALID && (
                <div tw="flex justify-between">
                  <div tw="w-12 self-end">
                    <img
                      tw="w-full rounded-full"
                      src="/images/avatar-x100.jpg"
                    />
                  </div>
                  <div tw="pl-4 pt-4 pr-4">
                    <div tw="shadow rounded border border-solid border-gray-200 p-2 text-black">
                      <Paragraph tw="italic">
                        来自『<span tw="font-bold">{data.chat.title}</span>
                        』的验证，请确认问题并选择您认为正确的答案。
                      </Paragraph>
                      <br />
                      <Paragraph tw="font-bold">{editintTitle}</Paragraph>
                      <br />
                      <Paragraph>
                        您还剩 <span tw="underline">300</span>{" "}
                        秒，通过可解除封印。
                      </Paragraph>
                    </div>
                    <div tw="flex flex-col mt-2">
                      {answers.map((ans, index) => (
                        <InlineKeybordButton key={index}>
                          <span>{ans.text}</span>
                        </InlineKeybordButton>
                      ))}
                    </div>
                  </div>
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
