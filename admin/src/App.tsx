import { MetaProvider, Title } from "@solidjs/meta";
import { Route, Router } from "@solidjs/router";
import { SideBar, TitleBar } from "./layouts";
import { DashboardPage } from "./pages";
import { metaState } from "./state";

export default () => {
  return (
    <MetaProvider>
      <Title>{metaState.title}</Title>
      <div class="w-[68rem] mx-auto flex">
        <SideBar />
        <div class="flex-1">
          <TitleBar />
          <Router base="/admin/v2">
            <Route path="/" component={DashboardPage} />
          </Router>
        </div>
      </div>
    </MetaProvider>
  );
};
