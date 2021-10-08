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

const EDITING_HISTORY = 1;
const EDITING_ADDRESS = 2;

const makeHistoriesEndpoint = () => `/admin/api/sponsorship_histories`;
const makeAddressesEndpoint = () => `/admin/api/sponsorship_addresses`;

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

const saveSponsorshipAddress = async ({
  id,
  name,
  description,
  text,
  image,
}) => {
  let endpoint = "/admin/api/sponsorship_addresses";
  let method = "POST";
  if (id) {
    endpoint = `/admin/api/sponsorship_addresses/${id}`;
    method = "PUT";
  }
  return fetch(endpoint, {
    method: method,
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      name: name,
      description: description,
      text: text,
      image: image,
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

const deleteSponsorshipAddress = async (id) => {
  const endpoint = `/admin/api/sponsorship_addresses/${id}`;
  const method = "DELETE";
  return fetch(endpoint, {
    method: method,
  }).then((r) => camelizeJson(r));
};

export default () => {
  const location = useLocation();
  const dispatch = useDispatch();

  const {
    data: historiesData,
    mutate: historiesMutate,
    error: historiesError,
  } = useSWR(makeHistoriesEndpoint());
  const {
    data: addressesData,
    mutate: addressesMutate,
    error: addressesError,
  } = useSWR(makeAddressesEndpoint());
  const [editingFlag, setEditingFlag] = useState(0);
  const [editingHistoryId, setEditingHistoryId] = useState(null);
  const [editingAddressId, setEditingAddressId] = useState(null);
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

  const [editingAddressName, setEditingAddressName] = useState("");
  const [editingAddressDescription, setEditingAddressDescription] =
    useState("");
  const [editingAddressText, setEditingAddressText] = useState("");
  const [editingAddressImage, setEditingAddressImage] = useState("");

  const handleIsEditing = useCallback(
    (flag) => {
      if (flag == editingFlag) setEditingFlag(0);
      else setEditingFlag(flag);
    },
    [editingFlag]
  );
  const initEditingHistoryContent = () => {
    setEditingFlag(0);

    setEditingHistoryId(null);
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

  const initEditingAddressContent = () => {
    setEditingFlag(0);

    setEditingAddressId(null);
    setEditingAddressName("");
    setEditingAddressDescription("");
    setEditingAddressText("");
    setEditingAddressImage("");
  };
  const handleCancelEditingHistoryClick = () => initEditingHistoryContent();
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

  const handleEditingAddressName = (e) => setEditingAddressName(e.target.value);
  const handleEditingAddressDescription = (e) =>
    setEditingAddressDescription(e.target.value);
  const handleEditingAddressText = (e) => setEditingAddressText(e.target.value);
  const handleEditingAddressImage = (e) =>
    setEditingAddressImage(e.target.value);

  const isLoaded = () =>
    !historiesError &&
    historiesData &&
    !historiesData.errors &&
    !addressesError &&
    addressesData &&
    !addressesData.errors;

  const checkEditintValid = useCallback(() => {
    if (!editingFlag) return EDITING_CHECK.NO_EDINTINT;

    return (
      (editingSelectedSponsor ||
        (editingSponsorTitle.trim() && editingSponsorContact.trim())) &&
      editingAmount.toString().trim() &&
      editingHasReached != null &&
      EDITING_CHECK.VALID
    );
  }, [
    editingFlag,
    editingSelectedSponsor,
    editingSponsorTitle,
    editingSponsorContact,
    editingAmount,
    editingHasReached,
  ]);

  const checkAddressEditintValid = useCallback(() => {
    if (editingFlag == 0) return EDITING_CHECK.NO_EDINTINT;

    return (
      (editingAddressText.trim() || editingAddressImage) &&
      editingAddressName.trim() &&
      EDITING_CHECK.VALID
    );
  }, [
    editingFlag,
    editingAddressName,
    editingAddressDescription,
    editingAddressText,
    editingAddressImage,
  ]);

  const handleSaveHistoryClick = useCallback(
    async (e) => {
      e.preventDefault();

      const result = await saveSponsorHistory({
        id: editingHistoryId,
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
        historiesMutate();
        // 初始化编辑内容
        initEditingHistoryContent();
      }
    },
    [
      editingHistoryId,
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
  const handleSaveAddressClick = useCallback(
    async (e) => {
      e.preventDefault();

      const result = await saveSponsorshipAddress({
        id: editingAddressId,
        name: editingAddressName,
        description: editingAddressDescription,
        text: editingAddressText,
        image: editingAddressImage,
      });

      if (result.errors) toastErrors(result.errors);
      else {
        // 保存成功
        addressesMutate();
        // 初始化编辑内容
        initEditingAddressContent();
      }
    },
    [
      editingAddressId,
      editingAddressName,
      editingAddressDescription,
      editingAddressText,
      editingAddressImage,
    ]
  );

  const handleHiddenClick = useCallback(
    (id) => {
      hiddenSponsorHistory(id).then((result) => {
        if (result.errors) toastErrors(result.errors);
        else historiesMutate();
      });
    },
    [historiesData]
  );

  const handleAddressDeleteClick = useCallback(
    (id) => {
      deleteSponsorshipAddress(id).then((result) => {
        if (result.errors) toastErrors(result.errors);
        else addressesMutate();
      });
    },
    [addressesData]
  );

  const handleEditHistoryClick = useCallback(
    (index) => {
      const sponsorshipHistory = historiesData.sponsorshipHistories[index];

      setEditingFlag(EDITING_HISTORY);
      setEditingHistoryId(sponsorshipHistory.id);
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
    [historiesData]
  );

  const handleEditAddressClick = useCallback(
    (index) => {
      const address = addressesData.sponsorshipAddresses[index];

      setEditingFlag(EDITING_ADDRESS);
      setEditingAddressId(address.id);
      setEditingAddressName(address.name);
      setEditingAddressDescription(address.description);
      setEditingAddressText(address.text || "");
      setEditingAddressImage(address.image || "");
    },
    [addressesData]
  );

  useEffect(() => {
    // 初始化编辑内容
    initEditingHistoryContent();
  }, [location]);

  useEffect(() => {
    if (historiesData && historiesData.sponsors) {
      const sponsorOptions = historiesData.sponsors.map((sponsor) => ({
        value: sponsor.id,
        label: sponsor.title,
      }));
      sponsorOptions.push({ value: null, label: "匿名" });

      setEditingSponsorOptions(sponsorOptions);
    }
  }, [historiesData]);

  const editingCheckResult = checkEditintValid();
  const addressEditingCheckResult = checkAddressEditintValid();

  let title = "赞助记录";

  useEffect(() => {
    // 初始化只读显示状态。
    dispatch(readonlyShown(false));
  }, [location]);

  useEffect(() => {
    if (historiesData && historiesData.errors)
      toastErrors(historiesData.errors);
    if (addressesData && addressesData.errors)
      toastErrors(addressesData.errors);
  }, [historiesData, addressesData]);

  return (
    <>
      <PageHeader title={title} />
      {isLoaded() ? (
        <PageBody>
          <PageSection>
            <header>
              <Title>历史列表</Title>
            </header>
            <main>
              {historiesData.sponsorshipHistories.length > 0 ? (
                <div tw="mt-4">
                  <ActionButton
                    onClick={() => handleIsEditing(EDITING_HISTORY)}
                  >
                    + 添加赞助历史
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
                      {historiesData.sponsorshipHistories.map(
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
                                onClick={() => handleEditHistoryClick(index)}
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
                  当前未添加任何赞助历史，
                  <span
                    tw="underline cursor-pointer text-blue-300"
                    onClick={() => handleIsEditing(EDITING_HISTORY)}
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
              <Title>地址列表</Title>
            </header>
            <main>
              {addressesData.sponsorshipAddresses.length > 0 ? (
                <div tw="mt-4">
                  <ActionButton
                    onClick={() => handleIsEditing(EDITING_ADDRESS)}
                  >
                    + 添加赞助地址
                  </ActionButton>
                  <Table tw="shadow rounded">
                    <Thead>
                      <Tr>
                        <Th tw="w-2/12">地址名称</Th>
                        <Th tw="w-3/12">地址说明</Th>
                        <Th tw="w-3/12">地址文本</Th>
                        <Th tw="w-2/12">地址图片</Th>
                        <Th tw="w-2/12 text-right">操作</Th>
                      </Tr>
                    </Thead>
                    <Tbody>
                      {addressesData.sponsorshipAddresses.map((address, i) => (
                        <Tr key={address.id}>
                          <Td tw="break-all">{address.name}</Td>
                          <Td tw="break-all">{address.description}</Td>
                          <Td tw="break-all">{address.text}</Td>
                          <Td tw="break-all">{address.image || "无"}</Td>
                          <Td tw="text-right">
                            <ActionButton
                              tw="mr-1"
                              onClick={() => handleEditAddressClick(i)}
                            >
                              编辑
                            </ActionButton>
                            <ActionButton
                              onClick={() =>
                                handleAddressDeleteClick(address.id)
                              }
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
                  当前未添加任何赞助地址，
                  <span
                    tw="underline cursor-pointer text-blue-300"
                    onClick={() => handleIsEditing(EDITING_ADDRESS)}
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
              <Title>正在编辑</Title>
            </header>
            <main>
              {editingFlag == EDITING_HISTORY && (
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
                        onClick={handleCancelEditingHistoryClick}
                      >
                        取消
                      </LabelledButton>
                    </div>
                    <div tw="flex-1 pl-10">
                      <LabelledButton
                        label="ok"
                        disabled={editingCheckResult !== EDITING_CHECK.VALID}
                        onClick={handleSaveHistoryClick}
                      >
                        保存
                      </LabelledButton>
                    </div>
                  </div>
                </form>
              )}

              {editingFlag == EDITING_ADDRESS && (
                <form>
                  <FormSection>
                    <FormLable>地址名称</FormLable>
                    <FormInput
                      tw="w-full lg:w-9/12"
                      value={editingAddressName}
                      onChange={handleEditingAddressName}
                    />
                  </FormSection>
                  <FormSection>
                    <FormLable>地址说明</FormLable>
                    <FormInput
                      tw="w-full lg:w-9/12"
                      value={editingAddressDescription}
                      onChange={handleEditingAddressDescription}
                    />
                  </FormSection>
                  <FormSection>
                    <FormLable>地址文本</FormLable>
                    <FormInput
                      tw="w-full lg:w-9/12"
                      value={editingAddressText}
                      onChange={handleEditingAddressText}
                    />
                  </FormSection>
                  <FormSection>
                    <FormLable>地址图片</FormLable>
                    <FormInput
                      tw="w-full lg:w-9/12"
                      value={editingAddressImage}
                      onChange={handleEditingAddressImage}
                    />
                  </FormSection>
                  <div tw="flex mt-2">
                    <div tw="flex-1 pr-10">
                      <LabelledButton
                        label="cancel"
                        onClick={initEditingAddressContent}
                      >
                        取消
                      </LabelledButton>
                    </div>
                    <div tw="flex-1 pl-10">
                      <LabelledButton
                        label="ok"
                        disabled={
                          addressEditingCheckResult !== EDITING_CHECK.VALID
                        }
                        onClick={handleSaveAddressClick}
                      >
                        保存
                      </LabelledButton>
                    </div>
                  </div>
                </form>
              )}
              {editingFlag == 0 && (
                <HintParagraph>请选择或新增一个记录。</HintParagraph>
              )}
            </main>
          </PageSection>
        </PageBody>
      ) : historiesError || addressesError ? (
        <PageReLoading mutate={mutate} />
      ) : (
        <PageLoading />
      )}
    </>
  );
};
