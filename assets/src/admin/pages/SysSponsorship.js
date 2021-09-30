import React, { useState, useCallback, useEffect } from "react";
import useSWR from "swr";
import tw, { styled } from "twin.macro";
import fetch from "unfetch";
import Select from "react-select";
import { useLocation } from "react-router-dom";
import { useDispatch } from "react-redux";
import { parseISO, format as formatDateTime } from "date-fns";

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

const dateTimeFormat = "yyyy-MM-dd HH:mm:ss";

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

const hasReachedOptions = [
  { value: false, label: "未达成" },
  { value: true, label: "已达成" },
];

const sponsorAssociatedOptions = [
  { value: "create", label: "不存在" },
  { value: "select", label: "已存在" },
];

const makeEndpoint = () => `/admin/api/sponsorship_histories`;

const saveSponsorHistory = async ({
  id,
  sponsor,
  sponsorId,
  amount,
  expectedTo,
  reachedAt,
  hasReached,
}) => {
  let endpoint = "/admin/api/sponsorship_histories";
  let method = "POST";
  if (id) {
    endpoint = `/admin/api/sponsorship_histories/${id}`;
    method = "PUT";
  }
  return fetch(endpoint, {
    method: method,
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      sponsor: sponsor,
      sponsor_id: sponsorId,
      amount: amount,
      expected_to: expectedTo,
      reached_at: reachedAt,
      has_reached: hasReached,
    }),
  }).then((r) => camelizeJson(r));
};

const constructSponsor = (title, introduction, homepage, contact) => {
  if (title && contact) {
    return {
      title,
      introduction,
      homepage,
      contact,
    };
  } else {
    return null;
  }
};

const hiddenSponsorHistory = async (id) => {
  const endpoint = `/admin/api/sponsorship_histories/${id}/hidden`;
  const method = "PUT";
  return fetch(endpoint, {
    method: method,
  }).then((r) => camelizeJson(r));
};

export default () => {
  const location = useLocation();
  const dispatch = useDispatch();

  const { data, mutate, error } = useSWR(makeEndpoint());
  const [isEditing, setIsEditing] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [editingSponsorAssociated, setEditingSponsorAssociated] = useState(
    sponsorAssociatedOptions[0]
  );
  const [editingSponsorOptions, setEditingSponsorOptions] = useState([]);
  const [editingSelectedSponsor, setEditingSelectedSponsor] = useState(null);
  const [editingSponsorTitle, setEditingSponsorTitle] = useState("");
  const [editingSponsorIntroduction, setEditingSponsorIntroduction] =
    useState("");
  const [editingSponsorHomepage, setEditingSponsorHomepage] = useState("");
  const [editingSponsorContact, setEditingSponsorContact] = useState("");
  const [editingAmount, setEditingAmount] = useState("");
  const [editingExpectedTo, setEditingExpectedTo] = useState("");
  const [editingReachedAt, setEditingReachedAt] = useState("");
  const [editingHasReached, setEditingHasReached] = useState(
    hasReachedOptions[0]
  );

  const handleIsEditing = () => setIsEditing(!isEditing);
  const initEditingContent = () => {
    setIsEditing(false);

    setEditingId(null);
    setEditingSponsorAssociated(sponsorAssociatedOptions[0]);
    setEditingSelectedSponsor(null);
    setEditingSponsorTitle("");
    setEditingSponsorIntroduction("");
    setEditingSponsorHomepage("");
    setEditingAmount("");
    setEditingExpectedTo("");
    setEditingReachedAt("");
    setEditingHasReached(hasReachedOptions[0]);
  };
  const handleCancelEditing = () => initEditingContent();
  const handleEditingSponsorAssociatedChange = (option) => {
    if (option.value === "create") {
      setEditingSelectedSponsor(null);
    }

    setEditingSponsorAssociated(option);
  };
  const handleEditingSelectedSponsorChange = (option) =>
    setEditingSelectedSponsor(option);
  const handleEditingSponsorTitleChange = (e) =>
    setEditingSponsorTitle(e.target.value.trim());
  const handleEditingSponsorIntroductionChange = (e) =>
    setEditingSponsorIntroduction(e.target.value.trim());
  const handleEditingSponsorHomepageChange = (e) =>
    setEditingSponsorHomepage(e.target.value.trim());
  const handleEditingSponsorContanctChange = (e) =>
    setEditingSponsorContact(e.target.value.trim());
  const handleEditingAmountChange = (e) => setEditingAmount(e.target.value);
  const handleEditingExpectedToChange = (e) =>
    setEditingExpectedTo(e.target.value.trim());
  const handleEditingReachedAtChange = (e) =>
    setEditingReachedAt(e.target.value.trim());
  const handleEditingHasReachedChange = (option) =>
    setEditingHasReached(option);

  const isLoaded = () => !error && data && !data.errors;

  const checkEditintValid = useCallback(() => {
    if (!isEditing) return EDITING_CHECK.NO_EDINTINT;

    return (
      (editingSelectedSponsor ||
        (editingSponsorTitle.trim() && editingSponsorContact.trim())) &&
      editingAmount.toString().trim() &&
      editingHasReached != null &&
      EDITING_CHECK.VALID
    );
  }, [
    isEditing,
    editingSelectedSponsor,
    editingSponsorTitle,
    editingSponsorContact,
    editingAmount,
    editingHasReached,
  ]);

  const handleSaveClick = useCallback(
    async (e) => {
      e.preventDefault();

      const result = await saveSponsorHistory({
        id: editingId,
        sponsor: constructSponsor(
          editingSponsorTitle,
          editingSponsorIntroduction,
          editingSponsorHomepage,
          editingSponsorContact
        ),
        sponsorId:
          (editingSelectedSponsor && editingSelectedSponsor.value) || null,
        amount: editingAmount,
        expectedTo: editingExpectedTo,
        reachedAt: editingReachedAt,
        hasReached: editingHasReached.value,
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
      editingSelectedSponsor,
      editingSponsorTitle,
      editingSponsorIntroduction,
      editingSponsorHomepage,
      editingSponsorContact,
      editingAmount,
      editingExpectedTo,
      editingReachedAt,
      editingHasReached,
    ]
  );

  const handleHiddenClick = useCallback(
    (id) => {
      hiddenSponsorHistory(id).then((result) => {
        if (result.errors) toastErrors(result.errors);
        else mutate();
      });
    },
    [data]
  );

  const handleEditClick = useCallback(
    (index) => {
      const sponsorshipHistory = data.sponsorshipHistories[index];

      setIsEditing(true);
      setEditingId(sponsorshipHistory.id);
      setEditingSponsorAssociated(sponsorAssociatedOptions[1]);
      if (sponsorshipHistory.sponsor) {
        setEditingSelectedSponsor({
          value: sponsorshipHistory.sponsor.id,
          label: sponsorshipHistory.sponsor.title,
        });
      }
      setEditingAmount(sponsorshipHistory.amount);
      setEditingExpectedTo(sponsorshipHistory.expectedTo || "");
      setEditingReachedAt(sponsorshipHistory.reachedAt);
      setEditingHasReached(
        sponsorshipHistory.hasReached
          ? hasReachedOptions[1]
          : hasReachedOptions[0]
      );
    },
    [data]
  );

  useEffect(() => {
    // 初始化编辑内容
    initEditingContent();
  }, [location]);

  useEffect(() => {
    if (data && data.sponsors) {
      const sponsorOptions = data.sponsors.map((sponsor) => ({
        value: sponsor.id,
        label: sponsor.title,
      }));
      sponsorOptions.push({ value: null, label: "匿名" });

      setEditingSponsorOptions(sponsorOptions);
    }
  }, [data]);

  const editingCheckResult = checkEditintValid();

  let title = "赞助记录";

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
            <header>
              <Title>记录列表</Title>
            </header>
            <main>
              {data.sponsorshipHistories.length > 0 ? (
                <div tw="mt-4">
                  <ActionButton onClick={handleIsEditing}>
                    + 添加赞助记录
                  </ActionButton>
                  <Table tw="shadow rounded">
                    <Thead>
                      <Tr>
                        <Th tw="w-2/12 pr-0">赞助人</Th>
                        <Th tw="w-2/12 text-center px-0">金额</Th>
                        <Th tw="w-2/12 text-center">是否达成</Th>
                        <Th tw="w-3/12">创建于</Th>
                        <Th tw="w-2/12 text-right">操作</Th>
                      </Tr>
                    </Thead>
                    <Tbody>
                      {data.sponsorshipHistories.map(
                        (sponsorshipHistory, index) => (
                          <Tr key={sponsorshipHistory.id}>
                            <Td tw="break-all pr-0">
                              {(sponsorshipHistory.sponsor &&
                                sponsorshipHistory.sponsor.title) ||
                                "匿名"}
                            </Td>
                            <Td tw="text-center px-0">
                              {sponsorshipHistory.amount}
                            </Td>
                            <Td tw="text-center">
                              {(sponsorshipHistory.hasReached && "是") || "否"}
                            </Td>
                            <Td>
                              {formatDateTime(
                                parseISO(sponsorshipHistory.insertedAt),
                                dateTimeFormat
                              )}
                            </Td>
                            <Td tw="text-right">
                              <ActionButton
                                tw="mr-1"
                                onClick={() => handleEditClick(index)}
                              >
                                编辑
                              </ActionButton>
                              <ActionButton
                                onClick={() =>
                                  handleHiddenClick(sponsorshipHistory.id)
                                }
                              >
                                隐藏
                              </ActionButton>
                            </Td>
                          </Tr>
                        )
                      )}
                    </Tbody>
                  </Table>
                </div>
              ) : (
                <HintParagraph>
                  当前未添加任何记录，
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
              <Title>当前编辑的记录</Title>
            </header>
            <main>
              {isEditing ? (
                <form>
                  <FormSection>
                    <FormLable>关联赞助人</FormLable>
                    <Select
                      tw="w-full lg:w-9/12"
                      value={editingSponsorAssociated}
                      options={sponsorAssociatedOptions}
                      onChange={handleEditingSponsorAssociatedChange}
                      isSearchable={false}
                    />
                  </FormSection>
                  {editingSponsorAssociated.value === "create" ? (
                    <>
                      <FormSection>
                        <FormLable>赞助人称谓</FormLable>
                        <FormInput
                          tw="w-full lg:w-9/12"
                          value={editingSponsorTitle}
                          onChange={handleEditingSponsorTitleChange}
                        />
                      </FormSection>
                      <FormSection>
                        <FormLable>赞助人简介</FormLable>
                        <FormInput
                          tw="w-full lg:w-9/12"
                          value={editingSponsorIntroduction}
                          onChange={handleEditingSponsorIntroductionChange}
                        />
                      </FormSection>
                      <FormSection>
                        <FormLable>赞助人链接</FormLable>
                        <FormInput
                          tw="w-full lg:w-9/12"
                          value={editingSponsorHomepage}
                          onChange={handleEditingSponsorHomepageChange}
                        />
                      </FormSection>
                      <FormSection>
                        <FormLable>赞助人联系方式</FormLable>
                        <FormInput
                          tw="w-full lg:w-9/12"
                          value={editingSponsorContact}
                          onChange={handleEditingSponsorContanctChange}
                        />
                      </FormSection>
                    </>
                  ) : (
                    <FormSection>
                      <FormLable>选择赞助人</FormLable>
                      <Select
                        tw="w-full lg:w-9/12"
                        placeholder="未选择"
                        value={editingSelectedSponsor}
                        options={editingSponsorOptions}
                        onChange={handleEditingSelectedSponsorChange}
                        isSearchable={false}
                      />
                    </FormSection>
                  )}
                  <FormSection>
                    <FormLable>赞助金额</FormLable>
                    <FormInput
                      tw="w-full lg:w-9/12"
                      type="number"
                      value={editingAmount}
                      onChange={handleEditingAmountChange}
                    />
                  </FormSection>
                  <FormSection>
                    <FormLable>期望用于</FormLable>
                    <FormInput
                      tw="w-full lg:w-9/12"
                      value={editingExpectedTo}
                      onChange={handleEditingExpectedToChange}
                    />
                  </FormSection>
                  <FormSection>
                    <FormLable>达成日期</FormLable>
                    <FormInput
                      tw="w-full lg:w-9/12"
                      value={editingReachedAt}
                      onChange={handleEditingReachedAtChange}
                    />
                  </FormSection>
                  <FormSection>
                    <FormLable>是否达成</FormLable>
                    <Select
                      tw="w-full lg:w-9/12"
                      value={editingHasReached}
                      options={hasReachedOptions}
                      onChange={handleEditingHasReachedChange}
                      isSearchable={false}
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
                <HintParagraph>请选择或新增一个记录。</HintParagraph>
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
