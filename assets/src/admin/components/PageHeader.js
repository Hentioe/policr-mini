import React from "react";
import "twin.macro";

import { Title } from "../components";

export default ({ title: title }) => {
  return (
    <>
      <Title>{title}</Title>
      <div tw="p-2 border border-solid border-0 border-b border-gray-300">
        <span tw="text-xl text-black">{title}</span>
      </div>
    </>
  );
};
