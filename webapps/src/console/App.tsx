import Drawer from "./layouts/Drawer";
import Main from "./layouts/Main";
import MenuBar from "./layouts/MenuBar";
import Root from "./layouts/Root";
import StaticBar from "./layouts/StaticBar";
import ViewBox from "./layouts/ViewBox";

export default () => {
  return (
    <Root>
      <ViewBox>
        <Drawer>
          <StaticBar />
          <MenuBar />
        </Drawer>
        <Main>
          Main
        </Main>
      </ViewBox>
    </Root>
  );
};
