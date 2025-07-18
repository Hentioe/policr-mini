import { MetaProvider, Title } from "@solidjs/meta";
import { Route, Router } from "@solidjs/router";
import { DashboardPage } from "./pages";
import { metaState } from "./state";

export default () => {
  return (
    <MetaProvider>
      <Title>{metaState.title}</Title>
      <Router base="/admin/v2">
        <Route path="/" component={DashboardPage} />
      </Router>
    </MetaProvider>
  );
};
