import { Route, Router, RouteSectionProps } from "@solidjs/router";
import Content from "./layouts/Content";
import Drawer from "./layouts/Drawer";
import Frame from "./layouts/Frame";
import Header from "./layouts/Header";
import MenuBar from "./layouts/MenuBar";
import Root from "./layouts/Root";
import StaticBar from "./layouts/StaticBar";
import ViewBox from "./layouts/ViewBox";
import Custom from "./pages/Custom";
import Dashboard from "./pages/Dashboard";
import Operations from "./pages/Operations";
import Permissions from "./pages/Permissions";
import Scheme from "./pages/Scheme";
import Verifications from "./pages/Verifications";
import Welcome from "./pages/Welcome";

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
        <Route path="/:chat_id/scheme" component={Scheme} />
        <Route path="/:chat_id/custom" component={Custom} />
        <Route path="/:chat_id/welcome" component={Welcome} />
        <Route path="/:chat_id/verifications" component={Verifications} />
        <Route path="/:chat_id/operations" component={Operations} />
        <Route path="/:chat_id/permissions" component={Permissions} />
        <Route path={["/:chat_id", "/:chat_id/dashboard"]} component={Dashboard} />
      </Router>
    </Root>
  );
};
