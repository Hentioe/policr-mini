import React, { useState, useCallback } from "react";
import useSWR from "swr";
import { useSelector } from "react-redux";
import tw, { styled } from "twin.macro";
import Select from "react-select";

import {
  PageHeader,
  PageBody,
  PageSection,
  PageLoading,
  NotImplemented,
} from "../components";

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
  ${tw`h-8 box-border rounded appearance-none border focus:outline-none focus:shadow-outline`};
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
const answerROWOptions = [
  { value: "Right", label: "正确" },
  { value: "Wrong", label: "错误" },
];

const Title = styled.span`
  color: #2f3235;
  ${tw`text-lg`}
`;

const initialAnswer = { row: answerROWOptions[1], text: "" };

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
  const [answers, setAnswers] = useState([initialAnswer]);

  const handleIsEditing = () => setIsEditing(!isEditing);
  const handleKitTypeChange = (value) => setEditingKitType(value);
  const handleCancelEditing = () => {
    setIsEditing(false);
    setAnswers([initialAnswer]);
  };
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

  const isLoaded = () => chatsState.isLoaded && data;

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
              <p tw="p-0 py-5 text-center text-lg text-gray-400 font-bold">
                当前未添加任何问题，
                <span tw="underline cursor-pointer" onClick={handleIsEditing}>
                  点此添加
                </span>
                。
              </p>
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
                    <FormInput tw="w-full lg:w-9/12" />
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
                          <FormInput tw="w-full inline" />
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
