import React, { useState, useCallback } from "react";
import useSWR from "swr";
import { useSelector } from "react-redux";
import tw, { styled } from "twin.macro";
import Select from "react-select";

import { PageHeader, PageBody, PageSection, PageLoading } from "../components";

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

const FormButton = styled.button`
  border: 0 solid #e2e8f0;
  border-color: hsl(0, 0%, 80%);
  ${tw`py-2 tracking-widest font-bold rounded-full bg-white cursor-pointer border hover:border-gray-100 hover:shadow hover:bg-gray-100`}
`;

const kitTypeOptions = [
  { value: "Text", label: "文字提问" },
  // { value: "Photo", label: "图片提问" },
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

const answerROWOptions = [
  { value: ROW.RIGHT, label: "正确" },
  { value: ROW.WRONG, label: "错误" },
];

const initialAnswer = { row: answerROWOptions[1], text: "我不明白" };

function makeEndpoint(chat_id) {
  return `/admin/api/chats/${chat_id}/customs`;
}

export default () => {
  const chatsState = useSelector((state) => state.chats);
  const { data, error } = useSWR(
    chatsState && chatsState.isLoaded && chatsState.selected
      ? makeEndpoint(chatsState.selected)
      : null
  );
  const [isEditing, setIsEditing] = useState(true);
  // const [editingId, setEditingId] = useState(0); // 为 0 或负数都为 `false`，可适用于只允许正数的 id 判断是否有效
  const [editingKitType, setEditingKitType] = useState(kitTypeOptions[0]);
  const [editintTitle, setEditingTitle] = useState("你明白正在编辑的东西吗？");
  const [answers, setAnswers] = useState([initialAnswer]);

  const handleIsEditing = () => setIsEditing(!isEditing);
  const handleKitTypeChange = (value) => setEditingKitType(value);
  const handleCancelEditing = () => {
    setIsEditing(false);
    setAnswers([initialAnswer]);
  };
  const handleTitleChange = (e) => setEditingTitle(e.target.value.trim());
  const handleAnswerROWChange = useCallback(
    (value, index) => {
      const newAnswers = [];
      // 如果编辑的不是第一个，插入数组头部
      if (index > 0) newAnswers.push(...answers.slice(0, index));
      // 插入编辑后的当前答案
      newAnswers.push({ ...answers[index], row: value });
      // 如果编辑的不是最后一个，追加数组尾部
      if (index < answers.length - 1)
        newAnswers.push(...answers.slice(index, answers.length - 1));
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
      const newAnswers = [];
      // 如果编辑的不是第一个，插入数组头部
      if (index > 0) newAnswers.push(...answers.slice(0, index));
      // 插入编辑后的当前答案
      newAnswers.push({ ...answers[index], text: text });
      // 如果编辑的不是最后一个，追加数组尾部
      if (index < answers.length - 1)
        newAnswers.push(...answers.slice(index, answers.length - 1));
      setAnswers(newAnswers);
    },
    [answers]
  );

  const isLoaded = () => chatsState.isLoaded && data;
  const checkEditintValid = useCallback(() => {
    if (!isEditing) return EDITING_CHECK.NO_EDINTINT;
    if (editintTitle.trim() == "") return EDITING_CHECK.EMPTY_TITLE;
    const rightAnswers = answers
      .filter((ans) => ans.text.trim() != "")
      .filter((ans) => ans.row.value == ROW.RIGHT);
    if (rightAnswers.length == 0) return EDITING_CHECK.MISSING_CORRECT;

    return EDITING_CHECK.VALID;
  }, [isEditing, editintTitle, answers]);

  const editingCheckResult = checkEditintValid();

  let title = "自定义";
  if (isLoaded()) title += ` / ${data.chat.title}`;

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
              <HintParagraph>
                当前未添加任何问题，
                <span tw="underline cursor-pointer" onClick={handleIsEditing}>
                  点此添加
                </span>
                。
              </HintParagraph>
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
                        <span
                          tw="text-blue-400 font-bold cursor-pointer"
                          onClick={() => handleAnswerAddOrDelete(index)}
                        >
                          {answers.length - 1 == index ? "添加" : "删除"}
                        </span>
                      </div>
                    </FormSection>
                  ))}
                  <div tw="flex">
                    <div tw="flex-1 pr-10">
                      <FormButton
                        tw="w-full text-white bg-red-600 hover:bg-red-500"
                        onClick={handleCancelEditing}
                      >
                        取消
                      </FormButton>
                    </div>
                    <div tw="flex-1 pl-10">
                      <FormButton tw="w-full text-white bg-green-600 hover:bg-green-500">
                        确认
                      </FormButton>
                    </div>
                  </div>
                </form>
              ) : (
                <p tw="text-center text-gray-700 font-bold">
                  请选择或新增一个问题。
                </p>
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
                      {answers.map((ans) => (
                        <InlineKeybordButton>
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
      ) : (
        <PageLoading />
      )}
    </>
  );
};
