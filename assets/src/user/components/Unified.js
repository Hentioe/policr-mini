import tw, { styled } from "twin.macro";

const UnifiedBox = styled.div`
  ${tw`mx-2 md:mx-4 lg:mx-8 xl:mx-16`}
`;

const UnifiedFlexBox = styled(UnifiedBox)`
  ${tw`flex`}
`;

export { UnifiedBox, UnifiedFlexBox };
