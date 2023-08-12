import React, { useEffect, useRef } from "react";
import tw, { styled } from "twin.macro";
import useSWR from "swr";
import { useDispatch } from "react-redux";
import { parseISO, format as formatDateTime } from "date-fns";
import { useLocation } from "react-router-dom";
import queryString from "query-string";

import waleLineSvg from "../../../static/svg/wale-line.svg";
import mobileMainBgSvg from "../../../static/svg/main_bg_mobile.svg";

import cloudlySvg from "../../../static/svg/cloudly.svg";
import mobileDeployBgSvg from "../../../static/svg/deploy_bg_mobile.svg";

import rectLightSvg from "../../../static/svg/rect-light.svg";
import mobileSponsorshipBgSvg from "../../../static/svg/sponsorship_bg_mobile.svg";

import heartSvg from "../../../static/svg/heart.svg";

import { open as openModal } from "../slices/modal";
import {
  Title,
  ErrorParagraph,
  UnifiedFlexBox,
  Confirm,
  ThirdPartyTerm,
  Sponsorship,
  DeployTermial,
  BackgroundContainer,
} from "../components";

const dateTimeFormat = "yyyy-MM-dd";

const InlineKeybordButton = styled.div`
  ${tw`shadow-sm bg-blue-400 text-white rounded-md px-4 py-2 text-sm mt-1 flex justify-center bg-opacity-75 cursor-pointer`}
`;

const Divider = styled.div`
  ${tw`mt-1`}
`;

const Paragraph = styled.p`
  ${tw`m-0`}
`;

const Table = styled.table`
  box-shadow: 0 0 2px 2px rgba(0, 0, 0, 0.07);
  ${tw`table-fixed border-collapse w-full rounded-xl`}
`;

const HeartsContainer = styled.div`
  ${tw`absolute pointer-events-none`}
  left: -10px;
  top: -10px;

  @media (max-width: 768px) {
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
  }
`;

const SponsorsHeart = styled.img.attrs(() => ({ src: heartSvg }))``;

const SponsorsHeart1 = styled(SponsorsHeart)`
  @keyframes sponsors-heart-1 {
    0% {
      opacity: 0;
      transform: scale3d(0.5, 0.5, 0.5) translateZ(0) rotate(0);
    }
    50% {
      opacity: 0.75;
    }
    100% {
      opacity: 0;
      transform: scale3d(0.75, 0.75, 0.75) translate3d(-125%, -100%, 0)
        rotate(-35deg);
    }
  }
  animation: sponsors-heart-1 5s cubic-bezier(0.535, 0.15, 0.425, 1) -1s infinite;
`;

const SponsorsHeart2 = styled(SponsorsHeart)`
  @keyframes sponsors-heart-2 {
    0% {
      opacity: 0;
      transform: scale3d(0.35, 0.35, 0.35) translateZ(0) rotate(0);
    }
    50% {
      opacity: 0.5;
    }
    100% {
      opacity: 0;
      transform: scale3d(0.5, 0.5, 0.5) translate3d(150%, -120%, 0)
        rotate(35deg);
    }
  }
  animation: sponsors-heart-2 6s cubic-bezier(0.535, 0.15, 0.425, 1) -2s infinite;
`;

const Thead = styled.thead`
  ${tw`bg-gray-100`}
`;
const Tr = styled.tr``;
const Th = styled.th`
  ${tw`text-gray-600 font-bold tracking-wider uppercase text-left py-3 px-2 border-b border-gray-200`}
`;
const Tbody = styled.tbody`
  ${tw``}
`;
const Td = styled.td`
  ${tw`py-2 px-2 text-sm text-gray-700 bg-white border-solid border-0 border-t border-gray-200`}
  ${({ endRow, startCol }) => endRow && startCol && tw`rounded-bl-xl`}
  ${({ endRow, endCol }) => endRow && endCol && tw`rounded-br-xl`}
`;

const ThirdPartiesTag = styled.span`
  ${tw`ml-2 text-xs bg-green-600 text-white p-1 rounded`}
`;

const GradientFont = styled.span`
  -webkit-text-fill-color: transparent;
  background: -webkit-linear-gradient(-70deg, #2188ff, #804eda);
  -webkit-background-clip: text;
`;

const GradientTitle = ({ children }) => {
  return (
    <div tw="mb-6 font-extrabold text-2xl md:text-5xl text-center md:text-left tracking-wide md:tracking-normal">
      <GradientFont>{children}</GradientFont>
    </div>
  );
};

const Quote = styled.div`
  &:before {
    color: #ea4aaa;
    content: "“";
    display: block;
    font-size: 4rem;
    font-weight: 800;
    left: -2.5rem;
    line-height: 1;
    position: absolute;
    top: -0.5rem;
  }
  position: relative;
  @media (max-width: 1280px) {
    &:before {
      left: 0;
      top: -2rem;
    }
  }
  ${tw`mt-8 xl:mt-0`}
`;

const Avatar = () => {
  return (
    <a href={`https://t.me/${_GLOBAL.botUsername}`} target="_blank">
      <img src="/own_photo" tw="w-full rounded-full shadow-sm" />
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
        href="https://mini.tcore.app/community"
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
  if (_GLOBAL.isIndependent) return null;
  else if (_GLOBAL.isThirdParty)
    return "https://mini.tcore.app/api/third_parties";
  else return "/api/third_parties";
};

export default () => {
  const location = useLocation();

  const { data: indexData, error: indexError } = useSWR("/api/index", fetcher);
  const { data: thirdPartiesData, error: thirdPartiesError } = useSWR(
    makeThirdPartiesEndpoint(),
    fetcher
  );

  const { data: sponsorshipHistoriesData, error: sponsorshipHistoriesError } =
    useSWR("/api/sponsorship_histories", fetcher);

  const prevSponsorshipHistoriesDataRef = useRef();
  const prevSponsorshipHistoriesData = prevSponsorshipHistoriesDataRef.current;

  useEffect(() => {
    prevSponsorshipHistoriesDataRef.current = sponsorshipHistoriesData;
  });

  const dispatch = useDispatch();

  if (indexError)
    return <ErrorParagraph>载入首页数据失败，请稍后重试。</ErrorParagraph>;

  const index = indexData || initialIndexData;
  const passRate = calculatePassRate(index);

  useEffect(() => {
    const params = queryString.parse(location.search);
    const sponsorshipToken = params.sponsorship;

    if (
      sponsorshipToken &&
      sponsorshipHistoriesData &&
      !prevSponsorshipHistoriesData
    ) {
      dispatch(
        openModal({
          content: (
            <Sponsorship
              token={sponsorshipToken}
              hints={sponsorshipHistoriesData.hints}
              addresses={sponsorshipHistoriesData.sponsorship_addresses}
            />
          ),
        })
      );
    }
  }, [location, sponsorshipHistoriesData]);

  return (
    <>
      <Title>首页</Title>
      <BackgroundContainer src={waleLineSvg} mobileSrc={mobileMainBgSvg}>
        <UnifiedFlexBox tw="mt-6 md:mt-10 lg:mt-20 flex-wrap">
          {/* 左边主要内容区域 */}
          <div tw="w-full lg:w-8/12">
            <GradientTitle>免费可自行部署的开源验证机器人</GradientTitle>
            <p tw="text-base md:text-2xl text-center md:text-left font-bold tracking-wide">
              <span tw="text-gray-900">
                使用本机器人改善群内环境，避免垃圾帐号的骚扰。
              </span>
            </p>
            <p tw="text-sm md:text-lg text-center md:text-left font-normal md:font-bold tracking-wider mr-0 lg:mr-10">
              <span tw="text-gray-700">
                本项目从 Policr
                机器人的开发和运营过程中吸取了丰富的经验，设计更加现代，功能单一不膨胀。在未来的更新过程中也只会继续改进核心功能和优化体验，本质保持不变。
              </span>
            </p>
            <div tw="mt-10 lg:mt-24 flex flex-wrap">
              {/* 验证数据 */}
              <div tw="w-full lg:w-7/12 flex">
                <div tw="flex-1 flex flex-col lg:pr-10">
                  <div tw="flex-1 self-start">
                    <span
                      style={{ color: "#1883FF" }}
                      tw="font-bold tracking-wider"
                    >
                      「已进行
                    </span>
                  </div>
                  <div tw="flex-1 self-center">
                    <Paragraph
                      style={{ color: "#F04E3E" }}
                      tw="text-6xl font-extrabold text-center underline"
                    >
                      {index.totals.verification_all}
                    </Paragraph>
                  </div>
                  <div tw="flex-1 self-end">
                    <span
                      style={{ color: "#1883FF" }}
                      tw="float-right font-bold tracking-wider"
                    >
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
                        <span tw="text-gray-700 font-bold">
                          次垃圾账号侵入】
                        </span>
                      </Paragraph>
                    </div>
                  </div>
                </div>
              </div>
              {/* 主要功能简介与导航 */}
              <div tw="hidden w-full lg:w-5/12 lg:flex flex-col">
                <div
                  style={{ borderColor: "#1883FF" }}
                  tw="py-3 flex-1 border-solid border-0 lg:border-l-4"
                >
                  <div tw="lg:ml-10">
                    <Paragraph tw="text-gray-600 mb-3">
                      在后台定制机器人的功能，管理封禁列表和查看验证日志
                    </Paragraph>
                    <a
                      style={{ color: "#1883FF" }}
                      tw="text-sm font-bold no-underline cursor-pointer"
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
                <div
                  style={{ borderColor: "#1883FF" }}
                  tw="mt-10 py-3 flex-1 border-solid border-0 lg:border-l-4"
                >
                  <div tw="lg:ml-10">
                    <Paragraph tw="text-gray-600 mb-3">
                      通过解答算术题、识别图片或自定义问答内容“考核”入群成员
                    </Paragraph>
                    <a
                      style={{ color: "#1883FF" }}
                      tw="text-sm font-bold no-underline cursor-pointer"
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
                <div tw="shadow rounded-md p-4 text-sm tracking-wide">
                  <span
                    style={{ color: "#F39C12" }}
                    tw="font-semibold cursor-pointer tracking-wider"
                  >
                    {_GLOBAL.botFirstName}
                  </span>
                  <Divider />
                  <Paragraph>
                    新成员{" "}
                    <span tw="text-blue-500 cursor-pointer tracking-tighter">
                      小███混
                    </span>{" "}
                    你好！
                  </Paragraph>
                  <br />
                  您当前需要完成验证才能解除限制，验证有效时间不超过{" "}
                  <span tw="underline">300</span>{" "}
                  秒。过期会被踢出或封禁，请尽快。
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
                <div tw="shadow rounded-md text-sm pb-4 tracking-wide">
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
                      您还剩 <span tw="underline">198</span>{" "}
                      秒，通过可解除封印。
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
      </BackgroundContainer>
      {/* 自主部署简介和导航 */}
      <BackgroundContainer
        tw="mt-10"
        src={cloudlySvg}
        mobileSrc={mobileDeployBgSvg}
      >
        <UnifiedFlexBox tw="py-8 md:py-16 flex-col">
          <div tw="flex flex-wrap">
            <div tw="w-full lg:w-7/12">
              <GradientTitle>构建自己的实例</GradientTitle>
              <p tw="text-base md:text-xl font-bold tracking-wide pr-0 lg:pr-2">
                通过简单的 Shell 命令和 Web 服务配置，即可部署在低至 512MB
                内存的 Linux 服务器上。
              </p>
              <Quote>
                <p tw="text-sm md:text-base text-gray-800 tracking-wider pr-0 lg:pr-10">
                  <span>
                    如果您正在使用自己部署的实例，且有开放服务的想法和比较包容的心态，欢迎申请注册成为社区运营实例。所有被视作社区运营的实例都应该是相对可靠的，会被本项目推荐到可选实例列表中。
                  </span>
                  <br />
                  <br />
                  <span tw="italic">
                    也因为如此申请成功的条件相对严苛，它主要是对服务稳定性的考察。
                  </span>
                </p>
              </Quote>

              <div tw="mt-6 text-center md:text-left">
                <button tw="px-6 py-4 font-bold shadow bg-green-500 border-0">
                  <a
                    tw="text-white"
                    href="https://github.com/Hentioe/policr-mini/wiki/%E8%87%AA%E8%A1%8C%E9%83%A8%E7%BD%B2%EF%BC%88%E6%9E%84%E5%BB%BA%E7%AC%AC%E4%B8%89%E6%96%B9%E5%AE%9E%E4%BE%8B%EF%BC%89"
                    target="_blank"
                  >
                    开始部署
                  </a>
                </button>

                <a
                  tw="ml-10 font-bold text-gray-900 cursor-pointer underline"
                  href="https://github.com/Hentioe/policr-mini/issues/115"
                  target="_blank"
                >
                  申请社区运营
                </a>
              </div>
            </div>
            <div tw="w-full lg:w-5/12 mt-4 lg:mt-0">
              <DeployTermial />
            </div>
          </div>

          <div tw="hidden md:block">
            <div tw="my-6 text-gray-800">
              <span tw="text-2xl font-extrabold">社区中开放服务的实例</span>
            </div>
            {thirdPartiesError || _GLOBAL.isIndependent ? (
              <div tw="text-gray-700 text-left inline-block">
                <span tw="pr-2 font-bold text-sm text-gray-700 inline">
                  {thirdPartiesError
                    ? "当前实例尚未注册，无法载入此列表"
                    : "独立运营实例，不获取此列表"}
                </span>
                <div tw="bg-gray-700 h-1 rounded-2xl "></div>
              </div>
            ) : thirdPartiesData ? (
              <Table>
                <Thead>
                  <Tr>
                    <Th tw="w-2/12 rounded-tl-xl">实例名称</Th>
                    <Th tw="w-5/12">实例描述</Th>
                    <Th tw="w-1/12 text-center">运行天数</Th>
                    <Th tw="w-2/12">机器人用户名</Th>
                    <Th tw="w-2/12 rounded-tr-xl">主页链接</Th>
                  </Tr>
                </Thead>
                <Tbody>
                  {thirdPartiesData.third_parties.map((thirdParty, i) => (
                    <Tr key={thirdParty.bot_username}>
                      <Td
                        endRow={i == thirdPartiesData.third_parties.length - 1}
                        startCol={true}
                      >
                        {thirdParty.name}
                      </Td>
                      <Td>
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
                      </Td>
                      <Td tw="text-center">{thirdParty.running_days}</Td>
                      <Td>
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
                      </Td>
                      <Td
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
                      </Td>
                    </Tr>
                  ))}
                </Tbody>
              </Table>
            ) : (
              <div tw="text-gray-700 text-left inline-block">
                <span tw="pr-2 font-bold text-sm text-gray-700 inline">
                  载入中……
                </span>
                <div tw="bg-gray-700 h-1 rounded-2xl "></div>
              </div>
            )}
          </div>
        </UnifiedFlexBox>
      </BackgroundContainer>
      {/* 赞助相关 */}
      {!_GLOBAL.isThirdParty ? (
        <BackgroundContainer
          src={rectLightSvg}
          mobileSrc={mobileSponsorshipBgSvg}
        >
          <UnifiedFlexBox tw="flex-col py-16">
            <div>
              <GradientTitle>投资并获得回报</GradientTitle>
              <p tw="text-center md:text-left text-base md:text-xl font-bold tracking-wide">
                <span tw="text-gray-900">
                  赞助您的团队依赖以建立业务的开源软件和服务。
                </span>
                <br />
                <span tw="text-gray-600">
                  资助开发者，可降低开发和运营消耗的个人成本，提高项目的完成度和性能以及服务的可靠性。
                </span>
              </p>

              <div tw="text-center md:text-left relative">
                <button
                  tw="px-4 py-2 select-none border-transparent shadow text-white bg-indigo-500 font-bold cursor-pointer"
                  onClick={() =>
                    dispatch(
                      openModal({
                        content: (
                          <Sponsorship
                            hints={sponsorshipHistoriesData.hints}
                            addresses={
                              sponsorshipHistoriesData.sponsorship_addresses
                            }
                          />
                        ),
                      })
                    )
                  }
                >
                  赞助我们
                </button>
                <HeartsContainer>
                  <SponsorsHeart1 />
                  <SponsorsHeart2 />
                </HeartsContainer>
              </div>
            </div>

            <div tw="hidden md:block">
              <div tw="mt-10 text-gray-800">
                <span tw="text-2xl font-extrabold">赞助人</span>
                <p tw="text-lg tracking-wide">
                  感谢这些出色的赞助人，是他们让项目和社区变得更好 ：）
                </p>
              </div>
              {sponsorshipHistoriesData ? (
                <Table>
                  <Thead>
                    <Tr>
                      <Th tw="w-2/12 rounded-tl-xl">赞助者</Th>
                      <Th tw="w-4/12">赞助者简介</Th>
                      <Th tw="w-4/12">期望用途</Th>
                      <Th tw="w-1/12 text-center">金额</Th>
                      <Th tw="w-1/12 text-right rounded-tr-xl">赞助日期</Th>
                    </Tr>
                  </Thead>
                  <Tbody>
                    {sponsorshipHistoriesData.sponsorship_histories.map(
                      (sponsorshipHistory, i) => (
                        <Tr key={sponsorshipHistory.id}>
                          <Td
                            endRow={
                              i ==
                              sponsorshipHistoriesData.sponsorship_histories
                                .length -
                                1
                            }
                            startCol={true}
                          >
                            {(sponsorshipHistory.sponsor &&
                              sponsorshipHistory.sponsor.title) ||
                              "匿名"}
                          </Td>
                          <Td>
                            {sponsorshipHistory.sponsor
                              ? sponsorshipHistory.sponsor.introduction || "无"
                              : "一群不愿留名的可爱之人"}
                          </Td>
                          <Td>{sponsorshipHistory.expected_to}</Td>
                          <Td tw="text-center">{sponsorshipHistory.amount}</Td>
                          <Td
                            tw="text-right"
                            endRow={
                              i ==
                              sponsorshipHistoriesData.sponsorship_histories
                                .length -
                                1
                            }
                            endCol={true}
                          >
                            {formatDateTime(
                              parseISO(sponsorshipHistory.reached_at),
                              dateTimeFormat
                            )}
                          </Td>
                        </Tr>
                      )
                    )}
                  </Tbody>
                </Table>
              ) : undefined}
            </div>
          </UnifiedFlexBox>
        </BackgroundContainer>
      ) : undefined}
    </>
  );
};
