import tw, { styled } from "twin.macro";

// TODO: 输入框的获得焦点时的阴影使用边框样式替代。
// 和 react-select 库默认的颜色（#2684FF）、宽度（1px）相同。

export default styled.textarea`
  border: 0 solid #e2e8f0;
  border-color: hsl(0, 0%, 80%);
  border-radius: 4px;
  border-width: 1px;
  ${tw`px-2 box-border appearance-none focus:outline-none focus:shadow-outline focus:border-input-active`};
`;
