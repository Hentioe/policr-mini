import { Toast, Toaster } from "@ark-ui/solid";
import { MetaProvider, Title } from "@solidjs/meta";
import { Route, Router } from "@solidjs/router";
import { SideBar, TitleBar } from "./layouts";
import { AssetsPage, CustomizePage, DashboardPage, ManagementPage, TasksPage, TermsPage } from "./pages";
import { metaState } from "./state";
import { toaster } from "./utils";

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
            <Route path="/assets" component={AssetsPage} />
            <Route path="/tasks" component={TasksPage} />
            <Route path="/terms" component={TermsPage} />
          </Router>
        </div>
      </div>
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
