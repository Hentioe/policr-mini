import "react";
import tw, { styled } from "twin.macro";

const UnifiedBox = styled.div.attrs({})`
  ${tw`mx-10`}
`;

const UnifiedFlexBox = styled(UnifiedBox).attrs({})`
  ${tw`flex`}
`;

export { UnifiedBox, UnifiedFlexBox };
