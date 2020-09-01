import tw, { styled } from "twin.macro";

const Paragraph = styled.p`
  ${tw`m-0`}
`;

export default styled(Paragraph)`
  ${tw`py-5 text-center text-lg text-gray-400 font-bold`}
`;
