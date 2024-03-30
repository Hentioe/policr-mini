import { Route, Router, RouteSectionProps } from "@solidjs/router";
import Content from "./layouts/Content";
import Drawer from "./layouts/Drawer";
import Frame from "./layouts/Frame";
import Header from "./layouts/Header";
import MenuBar from "./layouts/MenuBar";
import Root from "./layouts/Root";
import StaticBar from "./layouts/StaticBar";
import ViewBox from "./layouts/ViewBox";
import Dashboard from "./pages/Dashboard";
import Scheme from "./pages/Scheme";

const View = (props: RouteSectionProps) => (
  <ViewBox>
    <Drawer>
      <StaticBar />
      <MenuBar />
    </Drawer>
    <Content>
      <Frame>
        <Header />
        {props.children}
      </Frame>
    </Content>
  </ViewBox>
);

export default () => {
  return (
    <Root>
      <Router base="/console" root={View}>
        <Route path={["/:chat_id", "/:chat_id/dashboard"]} component={Dashboard} />
        <Route path="/:chat_id/scheme" component={Scheme} />
      </Router>
    </Root>
  );
};
