import React from "react";
import tw, { styled } from "twin.macro";
import useSWR from "swr";
import { useDispatch } from "react-redux";

import { open as openModal } from "../slices/modal";
import {
  Title,
  ErrorParagraph,
  UnifiedFlexBox,
  Confirm,
  ThirdPartyTerm,
} from "../components";

const InlineKeybordButton = styled.div`
  ${tw`shadow-sm bg-blue-400 text-white rounded-md px-4 py-2 text-sm mt-1 flex justify-center bg-opacity-75 cursor-pointer`}
`;

const Divider = styled.div`
  ${tw`mt-1`}
`;

const Paragraph = styled.p`
  ${tw`m-0`}
`;

const ThirdPartiesTable = styled.table`
  ${tw`table-fixed border-collapse w-full shadow-xl rounded-xl`}
`;
const ThirdPartiesThead = styled.thead`
  ${tw`bg-gray-100`}
`;
const ThirdPartiesTr = styled.tr``;
const ThirdPartiesTh = styled.th`
  ${tw`text-gray-600 font-bold tracking-wider uppercase text-left py-3 px-2 border-b border-gray-200`}
`;
const ThirdPartiesTbody = styled.tbody`
  ${tw``}
`;
const ThirdPartiesTd = styled.td`
  ${tw`py-2 px-2 text-sm text-gray-700 bg-white border-solid border-0 border-t border-gray-200`}
  ${({ endRow, startCol }) => endRow && startCol && tw`rounded-bl`}
  ${({ endRow, endCol }) => endRow && endCol && tw`rounded-br`}
`;

const ThirdPartiesTag = styled.span`
  ${tw`ml-2 text-xs bg-green-600 text-white p-1 rounded`}
`;

const Avatar = () => {
  return (
    <a href="https://t.me/policr_mini_bot" target="_blank">
      <img
        src="/images/avatar-100x100.jpg"
        tw="w-full rounded-full shadow-sm"
      />
    </a>
  );
};

const buildPageContentMissingConfirm = ({ title }) => (
  <Confirm title={title}>
    <span tw="text-gray-600">
      由于此项目暂未完全实现，此页面内容有待填充。更多细节请参阅
      <a
        tw="text-blue-600"
        target="_blank"
        href="https://t.me/policr_changelog"
      >
        更新频道
      </a>
      或在
      <a
        tw="text-blue-600"
        target="_blank"
        href="https://mini.telestd.me/community"
      >
        社群
      </a>
      寻求帮助。
    </span>
  </Confirm>
);

const fetcher = (url) => fetch(url).then((r) => r.json());
const initialIndexData = {
  totals: {
    verification_all: 0,
    verification_passed: 0,
    verification_timeout: 0,
  },
};

function calculatePassRate({ totals }) {
  const { verification_passed, verification_all } = totals;
  return ((verification_passed / verification_all) * 100).toFixed(2);
}

const makeThirdPartiesEndpoint = () => {
  if (_GLOBAL.isThirdParty) {
    return "https://mini.telestd.me/api/third_parties";
  } else {
    return "/api/third_parties";
  }
};

export default () => {
  const { data: indexData, error: indexError } = useSWR("/api/index", fetcher);
  const { data: thirdPartiesData, error: thirdPartiesError } = useSWR(
    makeThirdPartiesEndpoint(),
    fetcher
  );

  const dispatch = useDispatch();

  if (indexError)
    return <ErrorParagraph>载入首页数据失败，请稍后重试。</ErrorParagraph>;

  const index = indexData || initialIndexData;
  const passRate = calculatePassRate(index);

  return (
    <>
      <Title>首页</Title>
      <UnifiedFlexBox tw="mt-0 md:mt-10 lg:mt-20 flex-wrap">
        {/* 左边主要内容区域 */}
        <div tw="w-full lg:w-8/12">
          <p tw="text-blue-500 text-2xl text-center md:text-3xl lg:text-4xl lg:text-left font-bold tracking-widest">
            致力于自主部署使用的，由社区驱动的开源验证机器人。
          </p>
          <p tw="text-sm text-center md:text-base lg:text-left text-gray-600">
            本项目从 Policr
            机器人的开发和运营过程中吸取了丰富的经验，设计更加现代，功能单一不膨胀。在未来的更新过程中也只会继续改进核心功能和优化体验，本质保持不变。
          </p>
          <div tw="mt-10 lg:mt-24 flex flex-wrap">
            {/* 验证数据 */}
            <div tw="w-full lg:w-7/12 flex">
              <div tw="flex-1 flex flex-col lg:pr-10">
                <div tw="flex-1 self-start">
                  <span tw="text-blue-600 font-bold tracking-wider">
                    「已进行
                  </span>
                </div>
                <div tw="flex-1 self-center">
                  <Paragraph tw="text-6xl font-extrabold text-red-400 text-center underline">
                    {index.totals.verification_all}
                  </Paragraph>
                </div>
                <div tw="flex-1 self-end">
                  <span tw="float-right text-blue-600 font-bold tracking-wider">
                    次验证」
                  </span>
                </div>
                <div tw="flex flex-wrap mt-6 lg:mt-0">
                  <Paragraph>
                    <span tw="text-green-400 font-bold">【通过率：</span>
                    <span tw="text-pink-500 font-bold">{passRate}%</span>
                  </Paragraph>
                  <div tw="flex-1">
                    <Paragraph tw="float-right">
                      <span tw="text-gray-700 font-bold line-through">
                        拦截
                      </span>{" "}
                      <span tw="text-pink-500 font-bold">
                        {index.totals.verification_timeout}
                      </span>{" "}
                      <span tw="text-gray-700 font-bold">次垃圾账号侵入】</span>
                    </Paragraph>
                  </div>
                </div>
              </div>
            </div>
            {/* 主要功能简介与导航 */}
            <div tw="hidden w-full lg:w-5/12 lg:flex flex-col">
              <div tw="py-3 flex-1 border-solid border-0 lg:border-l-4 border-blue-500">
                <div tw="lg:ml-10">
                  <Paragraph tw="text-gray-600 mb-3">
                    在后台定制机器人的功能，管理封禁列表和查看验证日志
                  </Paragraph>
                  <a
                    tw="text-blue-500 text-sm font-bold no-underline cursor-pointer"
                    onClick={() => {
                      dispatch(
                        openModal({
                          content: buildPageContentMissingConfirm({
                            title: "使用指南",
                          }),
                        })
                      );
                    }}
                  >
                    &gt; 进入这里阅读后台使用指南
                  </a>
                </div>
              </div>
              <div tw="mt-10 py-3 flex-1 border-solid border-0 lg:border-l-4 border-blue-500">
                <div tw="lg:ml-10">
                  <Paragraph tw="text-gray-600 mb-3">
                    通过解答算术题、识别图片或自定义问答内容“考核”入群成员
                  </Paragraph>
                  <a
                    tw="text-blue-500 text-sm font-bold no-underline cursor-pointer"
                    onClick={() => {
                      dispatch(
                        openModal({
                          content: buildPageContentMissingConfirm({
                            title: "设定验证",
                          }),
                        })
                      );
                    }}
                  >
                    &gt; 来了解如何自己设定验证方案
                  </a>
                </div>
              </div>
            </div>
          </div>
        </div>
        {/* 右边验证展示区域 */}
        <div tw="hidden w-full lg:w-4/12 lg:flex flex-col content-between justify-between mt-10 lg:mt-0">
          {/* 验证入口消息, 开始 */}
          <div tw="flex justify-between">
            <div tw="w-2/12 self-end px-8">
              <Avatar />
            </div>
            <div tw="w-10/12">
              <div tw="shadow rounded-md p-4 text-sm">
                <span tw="text-red-700 font-semibold cursor-pointer">
                  {_GLOBAL.botFirstName}
                </span>
                <Divider />
                <Paragraph>
                  新成员 <span tw="text-blue-500 cursor-pointer">机░人</span>{" "}
                  你好！
                </Paragraph>
                <br />
                您当前需要完成验证才能解除限制，验证有效时间不超过{" "}
                <span tw="underline">300</span> 秒。过期会被踢出或封禁，请尽快。
              </div>
              <div tw="mt-2">
                <InlineKeybordButton>
                  <span tw="underline select-none">点此验证</span>
                </InlineKeybordButton>
              </div>
            </div>
          </div>
          {/* 验证入口消息, 结束 */}
          {/* 验证消息，开始 */}
          <div tw="flex justify-between mt-2">
            <div tw="w-2/12 self-end px-8">
              <Avatar />
            </div>
            <div tw="w-10/12">
              <div tw="shadow rounded-md text-sm pb-4">
                <img src="/images/et-400x225.jpg" tw="w-full rounded-t" />
                <div tw="px-4 pt-1">
                  <Paragraph tw="italic">
                    来自『<span tw="font-bold">POLICR · 中文社区</span>
                    』的验证，请确认问题并选择您认为正确的答案。
                  </Paragraph>
                  <br />
                  <Paragraph tw="font-bold">图片中的事物是？</Paragraph>
                  <br />
                  <Paragraph>
                    您还剩 <span tw="underline">198</span> 秒，通过可解除封印。
                  </Paragraph>
                </div>
              </div>
              <div tw="mt-2">
                <InlineKeybordButton>
                  <span tw="select-none">地铁</span>
                </InlineKeybordButton>
                <InlineKeybordButton>
                  <span tw="select-none">公路</span>
                </InlineKeybordButton>
                <InlineKeybordButton>
                  <span tw="select-none">外星人</span>
                </InlineKeybordButton>
              </div>
            </div>
          </div>
          {/* 验证消息，结束 */}
        </div>
      </UnifiedFlexBox>
      {/* 自主部署简介和导航 */}
      <div tw="mt-10 bg-gray-800">
        <UnifiedFlexBox tw="mt-10 py-16 flex-wrap">
          <div tw="w-full lg:w-7/12 mb-8 lg:mb-0">
            <p tw="text-2xl font-bold text-gray-200">构建自己的实例</p>
            <p tw="text-gray-300">
              通过简单的 Shell 命令和 Web 服务配置，即可部署在低至 512MB 内存的
              Linux 服务器上。
            </p>

            <a
              tw="mt-6 inline-block bg-green-500 border-0 text-white px-6 py-4 no-underline"
              href="https://github.com/Hentioe/policr-mini/wiki/%E8%87%AA%E8%A1%8C%E9%83%A8%E7%BD%B2%EF%BC%88%E6%9E%84%E5%BB%BA%E7%AC%AC%E4%B8%89%E6%96%B9%E5%AE%9E%E4%BE%8B%EF%BC%89"
              target="_blank"
            >
              让我们开始吧
            </a>
          </div>
          <div tw="w-full lg:w-5/12">
            <p tw="text-gray-200 italic tracking-wider">
              如果您正在使用自己部署的实例，且有开放服务的想法和比较包容的心态，欢迎申请注册成为社区运营实例。所有被视作社区运营的实例都应该是相对可靠的，会被本项目推荐到可选实例列表中。
            </p>
            <p tw="text-gray-200">
              也因为如此申请成功的条件相对严苛，它主要是对服务稳定性的考察。
            </p>
            <a
              tw="text-white float-right cursor-pointer underline"
              href="https://github.com/Hentioe/policr-mini/issues/115"
              target="_blank"
            >
              申请社区运营
            </a>
          </div>
        </UnifiedFlexBox>
      </div>
      <div tw="bg-indigo-400 hidden lg:block">
        <UnifiedFlexBox tw="flex-col py-16">
          <p tw="text-2xl font-bold text-gray-200">社区中开放服务的实例</p>

          {thirdPartiesError ? (
            <div>
              <p tw="text-gray-200">
                此列表加载失败，当前实例可能并未注册成为社区运营的实例。去
                <a
                  tw="text-gray-200"
                  href="https://mini.telestd.me#community_instances"
                  target="_blank"
                >
                  官网
                </a>
                看看？
              </p>

              <p tw="text-gray-200 italic float-right">
                注意：是否向注册成为社区运营实例或开放服务是第三方实例的拥有者的自愿行为，看到此内容并不表示当前实例存在任何问题。
              </p>
            </div>
          ) : thirdPartiesData ? (
            <ThirdPartiesTable>
              <ThirdPartiesThead>
                <ThirdPartiesTr>
                  <ThirdPartiesTh tw="w-2/12 rounded-tl">
                    实例名称
                  </ThirdPartiesTh>
                  <ThirdPartiesTh tw="w-5/12">实例描述</ThirdPartiesTh>
                  <ThirdPartiesTh tw="w-1/12 text-center">
                    运行天数
                  </ThirdPartiesTh>
                  <ThirdPartiesTh tw="w-2/12">机器人用户名</ThirdPartiesTh>
                  <ThirdPartiesTh tw="w-2/12 rounded-tr">
                    主页链接
                  </ThirdPartiesTh>
                </ThirdPartiesTr>
              </ThirdPartiesThead>
              <ThirdPartiesTbody>
                {thirdPartiesData.third_parties.map((thirdParty, i) => (
                  <ThirdPartiesTr key={thirdParty.bot_username}>
                    <ThirdPartiesTd
                      endRow={i == thirdPartiesData.third_parties.length - 1}
                      startCol={true}
                    >
                      {thirdParty.name}
                    </ThirdPartiesTd>
                    <ThirdPartiesTd>
                      {thirdParty.description || "无"}

                      {thirdPartiesData.official_index == i ? (
                        <ThirdPartiesTag tw="bg-green-600">
                          官方实例
                        </ThirdPartiesTag>
                      ) : undefined}

                      {thirdPartiesData.official_index == i &&
                      thirdPartiesData.current_index != i ? (
                        <ThirdPartiesTag tw="bg-gray-600">
                          非当前实例
                        </ThirdPartiesTag>
                      ) : undefined}

                      {thirdPartiesData.current_index == i ? (
                        <ThirdPartiesTag tw="bg-blue-600">
                          当前实例
                        </ThirdPartiesTag>
                      ) : undefined}
                    </ThirdPartiesTd>
                    <ThirdPartiesTd tw="text-center">
                      {thirdParty.running_days}
                    </ThirdPartiesTd>
                    <ThirdPartiesTd>
                      <a
                        tw="text-gray-700 no-underline cursor-pointer select-none"
                        href={`https://t.me/${thirdParty.bot_username}`}
                        target="_blank"
                        onClick={(e) => {
                          if (thirdPartiesData.official_index != i) {
                            e.preventDefault();

                            dispatch(
                              openModal({
                                content: (
                                  <ThirdPartyTerm
                                    instanceName={thirdParty.name}
                                    botUsername={thirdParty.bot_username}
                                  />
                                ),
                              })
                            );
                          }
                        }}
                      >
                        @{thirdParty.bot_username}
                      </a>
                    </ThirdPartiesTd>
                    <ThirdPartiesTd
                      tw="truncate"
                      endRow={i == thirdPartiesData.third_parties.length - 1}
                      endCol={true}
                    >
                      <a
                        tw="text-gray-700"
                        href={thirdParty.homepage}
                        target="_blank"
                      >
                        {thirdParty.homepage}
                      </a>
                    </ThirdPartiesTd>
                  </ThirdPartiesTr>
                ))}
              </ThirdPartiesTbody>
            </ThirdPartiesTable>
          ) : (
            <span tw="text-gray-200">载入中……</span>
          )}
        </UnifiedFlexBox>
      </div>
    </>
  );
};
