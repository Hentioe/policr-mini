import React from "react";
import tw, { styled } from "twin.macro";

const ButtonBox = styled.button.attrs(({ disabled: disabled }) => ({
  disabled: disabled,
}))`
  border: 0 solid #e2e8f0;
  border-color: hsl(0, 0%, 80%);
  ${({ label }) => label === "cancel" && `background-color: #ec4628;`}
  ${({ label }) => label === "ok" && `background-color: #2884ec;`}
  ${tw`py-2 w-full tracking-widest font-bold rounded-full cursor-pointer text-white hover:shadow`}
  ${({ disabled: disabled }) => disabled && tw`cursor-not-allowed`}
`;

export default ({ disabled, children, label, onClick }) => (
  <ButtonBox disabled={disabled} label={label} onClick={onClick}>
    {children}
  </ButtonBox>
);
