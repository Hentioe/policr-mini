import { Toast, Toaster } from "@ark-ui/solid";
import { MetaProvider, Title } from "@solidjs/meta";
import { Route, Router } from "@solidjs/router";
import { Drawer, TitleBar } from "./layouts";
import { ExamplePage } from "./pages";
import { metaState } from "./state";
import { toaster } from "./utils";

export default () => {
  return (
    <MetaProvider>
      <Title>{metaState.pageTitle}</Title>
      <Drawer />
      <TitleBar />
      <Router base="/console/v2">
        <Route path="/" component={ExamplePage} />
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
