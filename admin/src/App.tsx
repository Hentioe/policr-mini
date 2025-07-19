import { MetaProvider, Title } from "@solidjs/meta";
import { Route, Router } from "@solidjs/router";
import { SideBar, TitleBar } from "./layouts";
import { AlbumsPage, CustomizePage, DashboardPage, ManagementPage, TasksPage, TermsPage } from "./pages";
import { metaState } from "./state";

export default () => {
  return (
    <MetaProvider>
      <Title>{metaState.pageTitle}</Title>
      <div class="w-[68rem] mx-auto flex">
        <SideBar />
        <div class="flex-1">
          <TitleBar />
          <Router base="/admin/v2">
            <Route path="/" component={DashboardPage} />
            <Route path="/customize" component={CustomizePage} />
            <Route path="/management" component={ManagementPage} />
            <Route path="/albums" component={AlbumsPage} />
            <Route path="/tasks" component={TasksPage} />
            <Route path="/terms" component={TermsPage} />
          </Router>
        </div>
      </div>
    </MetaProvider>
  );
};
