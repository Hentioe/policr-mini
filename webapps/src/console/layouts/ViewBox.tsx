import { JSX } from "solid-js";
import tw, { styled } from "twin.macro";

const Root = styled.div({
  ...tw`w-full h-full flex justify-center`,
});

const Box = styled.div({
  background: `linear-gradient(to bottom right, #fbb6e1, #bceabc)`,
  ...tw`flex h-full w-full lg:w-[80rem] border-x border-zinc-300 lg:shadow`,
});

// 视图盒子，主要内容的容器。
// 主要样式：宽度限制，居中，内容区域背景。
export default (props: { children: JSX.Element }) => {
  return (
    <Root>
      <Box>
        {props.children}
      </Box>
    </Root>
  );
};
