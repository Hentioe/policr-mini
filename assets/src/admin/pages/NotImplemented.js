import React from "react";
import { Title } from "../components";
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
      <Title>未实现</Title>
      <div tw="w-full">
        <p tw="text-center text-xl font-bold text-gray-400 tracking-wide">
          未实现
        </p>
      </div>
    </>
  );
};
