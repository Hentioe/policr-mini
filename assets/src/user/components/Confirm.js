import React from "react";
import tw, { styled } from "twin.macro";
import { useDispatch } from "react-redux";

import { close } from "../slices/modal";

const ConfirmContainer = styled.div`
  ${tw`rounded shadow-lg px-8 py-6 bg-white w-64 md:w-auto`}
`;

const ActionButton = styled.button`
  ${tw`px-4 py-1 border-0 rounded shadow bg-blue-400 text-white font-bold hover:bg-blue-300 hover:text-black cursor-pointer select-none`}
`;

export default ({ children, title }) => {
  const dispatch = useDispatch();

  return (
    <ConfirmContainer>
      {title != undefined ? <span tw="font-bold">{title}</span> : undefined}

      <div tw="mt-6">{children}</div>
      <div tw="mt-6 flex justify-end">
        <ActionButton
          onClick={() => {
            dispatch(close());
          }}
        >
          确定
        </ActionButton>
      </div>
    </ConfirmContainer>
  );
};
