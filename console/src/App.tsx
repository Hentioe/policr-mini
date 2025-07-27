import { Toast, Toaster } from "@ark-ui/solid";
import { MetaProvider, Title } from "@solidjs/meta";
import { Route, Router, RouteSectionProps } from "@solidjs/router";
import { Drawer, NavigationBar, Overlay, TitleBar } from "./layouts";
import { ControlPage, CustomizePage, HistoriesPage, StatsPage } from "./pages";
import { metaState } from "./state";
import { toaster } from "./utils";

const Layout = (props: RouteSectionProps) => {
  return (
    <>
      <Drawer /> {/* 抽屉菜单 */}
      <Overlay /> {/* 遮罩层 */}
      <TitleBar /> {/* 标题栏 */}
      {props.children} {/* 页面内容 */}
      <NavigationBar /> {/* 底部导航栏 */}
    </>
  );
};

export default () => {
  return (
    <MetaProvider>
      <Title>{metaState.pageTitle}</Title>
      <Router base="/console/v2" root={Layout}>
        <Route path={["/stats", "/"]} component={StatsPage} />
        <Route path="/control" component={ControlPage} />
        <Route path="/customize" component={CustomizePage} />
        <Route path="/histories" component={HistoriesPage} />
      </Router>
      <Toaster toaster={toaster}>
        {(toast) => (
          <Toast.Root>
            <Toast.Title>{toast().title}</Toast.Title>
            <Toast.Description>{toast().description}</Toast.Description>
          </Toast.Root>
        )}
      </Toaster>
    </MetaProvider>
  );
};
