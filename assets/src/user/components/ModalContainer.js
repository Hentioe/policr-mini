import React from "react";
import tw, { styled } from "twin.macro";

const ModalContainer = styled.div`
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  ${tw`absolute z-50`}
`;

export default ({ children }) => {
  return <ModalContainer>{children}</ModalContainer>;
};
