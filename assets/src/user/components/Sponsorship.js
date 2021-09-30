import React, { useCallback, useState } from "react";
import tw, { styled } from "twin.macro";
import Select from "react-select";
import { useDispatch } from "react-redux";

import { close } from "../slices/modal";
import { camelizeJson, errorsToString } from "../helper";

const Input = styled.input.attrs(({ type = "text" }) => ({
  type: type,
}))`
  border: 0 solid #e2e8f0;
  border-color: hsl(0, 0%, 80%);
  height: 38px;
  line-height: 38px;
  border-radius: 4px;
  border-width: 1px;
  ${tw`px-2 box-border appearance-none focus:outline-none focus:shadow-outline focus:border-input-active`};
`;

const FormInput = styled(Input)`
  ${tw`w-8/12`}
`;

const FormLine = styled.div`
  ${tw`flex items-center text-gray-800 mt-2`}
`;

const FormLabel = styled.label`
  ${tw`w-4/12`}
`;

const FromHint = ({ children }) => {
  return (
    <div tw="flex">
      <div tw="w-4/12"></div>
      <span tw="w-8/12 mt-1 text-xs font-bold text-gray-600">{children}</span>
    </div>
  );
};

const hintsToSelectOptions = (hints) =>
  hints.map((hint) => ({
    value: hint.ref,
    label: hint.expected_to,
    amount: hint.amount,
  }));

const saveSponsorshipHistory = async ({
  token,
  uuid,
  sponsor,
  expectedTo,
  amount,
}) => {
  let endpoint = "/api/sponsorship_histories";
  let method = "POST";
  return fetch(endpoint, {
    method: method,
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      token: token,
      uuid: uuid,
      sponsor: sponsor,
      expected_to: expectedTo,
      amount: amount,
    }),
  }).then((r) => camelizeJson(r));
};

const isEmpty = (value) => value == null || value.toString().trim() == "";

export default ({ hints = [], token = null }) => {
  const dispatch = useDispatch();

  const [isUseUuid, setIsUseUuid] = useState(false);
  const [editingToken, setEditingToken] = useState(token);
  const [editingUuid, setEditingUuid] = useState(null);
  const [editingSponsorTitle, setEditingSponsorTitle] = useState(null);
  const [editingSponsorContact, setEditingSponsorContact] = useState(null);
  const [editingSponsorHomepage, setEditingSponsorHomepage] = useState(null);
  const [editingSponsorIntroduction, setEditingSponsorIntroduction] =
    useState(null);
  const [editingExpectedToOption, setEditingExpectedToOption] = useState(null);
  const [editingAmount, setEditingAmount] = useState(null);
  const [postSuccessed, setPostSuccessed] = useState(false);
  const [successedUuid, setSuccessedUuid] = useState(null);

  const handleUseUuidClick = useCallback(() => {
    if (isUseUuid) {
      setEditingUuid(null);
    }

    setIsUseUuid(!isUseUuid);
  });

  const handleEditingUuidChange = (e) => setEditingUuid(e.target.value.trim());
  const handleEditingTokenChange = (e) =>
    setEditingToken(e.target.value.trim());
  const handleEditingSponsorTitleChange = (e) =>
    setEditingSponsorTitle(e.target.value.trim());
  const handleEditingSponsorContactChange = (e) =>
    setEditingSponsorContact(e.target.value.trim());
  const handleEditingSponsorHomepageChange = (e) =>
    setEditingSponsorHomepage(e.target.value.trim());
  const handleEditingSponsorIntroductionChange = (e) =>
    setEditingSponsorIntroduction(e.target.value.trim());
  const handleEditingExpectedToOptionChange = (option) => {
    setEditingExpectedToOption(option);
    setEditingAmount(option.amount);
  };
  const handleEditingAmountChange = (e) =>
    setEditingAmount(e.target.value.trim());

  const [errorMsg, setErrorMsg] = useState(null);

  const handleBackFormClick = () => {
    setPostSuccessed(false);
    setSuccessedUuid(null);
  };
  const handleCloseClick = () => dispatch(close());

  const handleSaveClick = useCallback(async () => {
    if (isEmpty(editingToken)) {
      setErrorMsg("未填写赞助口令。");
      return;
    }

    if (
      isEmpty(editingUuid) &&
      (isEmpty(editingSponsorTitle) || isEmpty(editingSponsorContact))
    ) {
      setErrorMsg("未填写必要的赞助者信息。");
      return;
    }

    if (editingExpectedToOption == null) {
      setErrorMsg("未选择期望用途。");
      return;
    }

    if (isEmpty(editingAmount)) {
      setErrorMsg("未填写赞助金额。");
      return;
    }

    setErrorMsg(null);

    const result = await saveSponsorshipHistory({
      token: editingToken,
      uuid: editingUuid,
      sponsor: {
        title: editingSponsorTitle,
        contact: editingSponsorContact,
        homepage: editingSponsorHomepage,
        introduction: editingSponsorIntroduction,
      },
      expectedTo:
        (editingExpectedToOption && editingExpectedToOption.value) || null,
      amount: editingAmount,
    });

    if (result.errors) {
      setErrorMsg(errorsToString(result.errors));
    } else {
      setPostSuccessed(true);
      setSuccessedUuid(editingUuid || result.uuid);
    }
  }, [
    editingToken,
    editingUuid,
    editingSponsorTitle,
    editingSponsorContact,
    editingSponsorHomepage,
    editingSponsorIntroduction,
    editingExpectedToOption,
    editingAmount,
  ]);

  return (
    <div tw="w-80 md:w-110 p-4 bg-white rounded-lg">
      <header tw="text-center border-0 border-b border-solid border-gray-400 pb-3">
        <span tw="text-lg font-bold">赞助此项目</span>
      </header>
      <main tw="mt-4">
        {!postSuccessed ? (
          <>
            <form tw="flex flex-col">
              <FormLine>
                <FormLabel>赞助口令</FormLabel>
                <FormInput
                  value={editingToken || ""}
                  onChange={handleEditingTokenChange}
                />
              </FormLine>
              <FromHint>
                为御防攻击并关联创建人，需私聊机器人 <code>/sponsorship</code>{" "}
                命令获取口令
              </FromHint>
              {isUseUuid ? (
                <>
                  <FormLine>
                    <FormLabel>UUID</FormLabel>
                    <FormInput
                      value={editingUuid || ""}
                      onChange={handleEditingUuidChange}
                    />
                  </FormLine>
                  <FromHint>请不要公开 UUID，虽然它没有危害性</FromHint>
                </>
              ) : (
                <>
                  <FormLine>
                    <FormLabel>您的称谓</FormLabel>
                    <FormInput
                      value={editingSponsorTitle || ""}
                      onChange={handleEditingSponsorTitleChange}
                    />
                  </FormLine>
                  <FromHint>
                    个人可用昵称或 x 先生/女士，企业可用产品或公司名称
                  </FromHint>
                  <FormLine>
                    <FormLabel>联系方式</FormLabel>
                    <FormInput
                      value={editingSponsorContact || ""}
                      type="email"
                      onChange={handleEditingSponsorContactChange}
                    />
                  </FormLine>
                  <FromHint>当前仅限邮箱地址，此数据无法被外部获取</FromHint>
                  <FormLine>
                    <FormLabel>您的主页</FormLabel>
                    <FormInput
                      placeholder="可选"
                      value={editingSponsorHomepage || ""}
                      onChange={handleEditingSponsorHomepageChange}
                    />
                  </FormLine>
                  <FromHint>赞助列表中可跳转的称谓链接即主页</FromHint>
                  <FormLine>
                    <FormLabel>您的简介</FormLabel>
                    <FormInput
                      placeholder="可选"
                      value={editingSponsorIntroduction || ""}
                      onChange={handleEditingSponsorIntroductionChange}
                    />
                  </FormLine>
                  <FromHint>可用作企业产品的宣传介绍或个人自我介绍</FromHint>
                </>
              )}
              <FormLine>
                <FormLabel>期望用途</FormLabel>
                <Select
                  tw="w-8/12"
                  placeholder="未选择"
                  value={editingExpectedToOption}
                  options={hintsToSelectOptions(hints)}
                  onChange={handleEditingExpectedToOptionChange}
                  isSearchable={false}
                />
              </FormLine>
              <FromHint>自定义此次赞助所期望的用途，需联系作者说明</FromHint>
              <FormLine>
                <FormLabel>赞助金额</FormLabel>
                <FormInput
                  type="number"
                  value={editingAmount || ""}
                  onChange={handleEditingAmountChange}
                />
              </FormLine>
              <FromHint>您可以修改此处的预设金额，量力而行</FromHint>
            </form>

            <div tw="mt-2">
              <div tw="flex justify-between">
                <span
                  tw="text-xs text-gray-600 underline cursor-pointer"
                  onClick={handleUseUuidClick}
                >
                  {isUseUuid
                    ? "手动创建关联身份"
                    : "曾经赞助过？点此输入 UUID 关联身份"}
                </span>

                {errorMsg ? (
                  <span tw="text-xs text-red-600">{errorMsg}</span>
                ) : (
                  <span
                    tw="text-xs text-gray-600 cursor-pointer"
                    onClick={handleCloseClick}
                  >
                    我不想赞助了
                  </span>
                )}
              </div>

              <button
                tw="mt-3 py-2 w-full border-transparent rounded-lg shadow text-white font-bold cursor-pointer bg-green-500 cursor-pointer"
                onClick={handleSaveClick}
              >
                提交
              </button>
            </div>
          </>
        ) : (
          <>
            <div tw="flex flex-col">
              <p tw="text-2xl text-center font-extrabold">
                感谢您提交的赞助承诺
              </p>
              <p tw="text-gray-800 tracking-wide">
                请牢记您的
                UUID，它能代表您的赞助者身份。并且在未来它仍然会有新的作用。
              </p>
              <p tw="text-xl text-center font-bold text-red-600">
                {successedUuid}
              </p>

              <p tw="text-gray-800 tracking-wide">
                <span>作者已在后台收到通知，请等候。亦可主动联系</span>
                <a
                  tw="text-gray-800"
                  target="_blank"
                  href="https://t.me/Hentioe"
                >
                  作者
                </a>
                。
              </p>

              <div tw="flex justify-between">
                <button
                  tw="py-2 border-transparent rounded shadow text-white font-bold bg-blue-500 cursor-pointer"
                  onClick={handleBackFormClick}
                >
                  返回赞助表单
                </button>
                <button
                  tw="py-2 border-transparent rounded shadow text-white font-bold bg-gray-400 cursor-pointer"
                  onClick={handleCloseClick}
                >
                  关闭赞助窗口
                </button>
              </div>
            </div>
          </>
        )}
      </main>
    </div>
  );
};
