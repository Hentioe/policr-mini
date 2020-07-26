import React from "react";
import { Title, NotImplemented } from "../components";
import { useSelector } from "react-redux";
import "twin.macro";
import MoonLoader from "react-spinners/MoonLoader";

export default () => {
  const { isLoaded } = useSelector((state) => state.chats);

  if (!isLoaded)
    return (
      <div tw="flex justify-center mt-10">
        <MoonLoader size={25} color="#47A8D8" />
      </div>
    );

  return (
    <>
      <Title>数据统计</Title>
      <div>
        <NotImplemented />
      </div>
    </>
  );
};
