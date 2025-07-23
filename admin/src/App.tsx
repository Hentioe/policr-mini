import { Toast, Toaster } from "@ark-ui/solid";
import { MetaProvider, Title } from "@solidjs/meta";
import { Route, Router } from "@solidjs/router";
import { QueryClient, QueryClientProvider } from "@tanstack/solid-query";
import { createSignal, onMount } from "solid-js";
import { mainBg } from "./assets";
import { WindowToArrow } from "./components";
import { SideBar, TitleBar } from "./layouts";
import { AssetsPage, CustomizePage, DashboardPage, ManagementPage, TasksPage, TermsPage } from "./pages";
import { metaState } from "./state";
import { toaster } from "./utils";
import { WindowDetector } from "./utils";

const client = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
    },
  },
});

export default () => {
  const [isTooNarrow, setIsTooNarrow] = createSignal(false);

  const onNarrow = () => setIsTooNarrow(true);
  const onWide = () => setIsTooNarrow(false);

  const windowDetector = new WindowDetector({
    cssVariable: "--spacing-app-x",
    onNarrow: onNarrow,
    onWide: onWide,
  });

  onMount(() => {
    windowDetector.init();
  });

  return (
    <QueryClientProvider client={client}>
      <MetaProvider>
        <Title>{metaState.pageTitle}</Title>
        <div
          class="w-app-x h-full max-h-full mx-auto flex rounded-[2rem] shadow border border-zinc-200 overflow-hidden full-bg"
          style={{
            "background": `url("${mainBg}")`,
            "background-repeat": "no-repeat",
            "background-position": "center center",
            "background-size": "cover",
          }}
        >
          <SideBar />
          <div class="flex-1 flex flex-col">
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
        <WindowToArrow open={isTooNarrow()} />
        <Toaster toaster={toaster}>
          {(toast) => (
            <Toast.Root>
              <Toast.Title>{toast().title}</Toast.Title>
              <Toast.Description>{toast().description}</Toast.Description>
            </Toast.Root>
          )}
        </Toaster>
      </MetaProvider>
    </QueryClientProvider>
  );
};
