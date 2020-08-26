import React from "react";
import tw, { styled } from "twin.macro";
import { Link } from "react-router-dom";

const Button = styled.span`
  ${tw`cursor-pointer text-gray-600 hover:text-gray-500`}
  ${({ disabled }) => (disabled ? tw`text-gray-100` : undefined)}
`;

const LinkButton = styled(Link)`
  ${tw`no-underline text-gray-600 hover:text-gray-500`}
  ${({ disabled }) => (disabled ? tw`text-gray-100` : undefined)}
`;

export default ({ begin, ending, linkify, upTo, downTo }) => (
  <div tw="bg-gray-100 flex justify-between py-2 px-2">
    {linkify ? (
      <LinkButton to={upTo}>上一页</LinkButton>
    ) : (
      <Button>上一页</Button>
    )}

    {begin < ending ? (
      <span>
        第 {begin} 到第 {ending} 条记录
      </span>
    ) : (
      <span>第 {begin} 条往后没有记录</span>
    )}
    {linkify ? (
      <LinkButton to={downTo}>下一页</LinkButton>
    ) : (
      <Button>下一页</Button>
    )}
  </div>
);
