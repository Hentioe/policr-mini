import Root from "./layouts/Root";
import ViewBox from "./layouts/ViewBox";

export default () => {
  return (
    <Root>
      <ViewBox>
        <div tw="text-red-600">
          Console
        </div>
      </ViewBox>
    </Root>
  );
};
