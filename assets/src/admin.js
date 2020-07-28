import "../styles/admin.scss";

import React from "react";
import ReactDOM from "react-dom";
import "twin.macro";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import thunkMiddleware from "redux-thunk";
import reduxLogger from "redux-logger";
import { BrowserRouter as Router, Switch, Route } from "react-router-dom";
import { SWRConfig } from "swr";

import { Sidebar, Chats } from "./admin/components";
import {
  StatisticsPage,
  SchemePage,
  TemplatePage,
  LogsPage,
  BannedPage,
  PermissionsPage,
  PropertiesPage,
  CustomPage,
} from "./admin/pages";

import Reducers from "./admin/reducers";

const DEBUG = process.env.NODE_ENV == "development";
const middlewares = [thunkMiddleware, DEBUG && reduxLogger].filter(Boolean);

const store = configureStore({
  reducer: Reducers,
  middleware: middlewares,
});

const App = () => {
  return (
    <React.StrictMode>
      <Provider store={store}>
        <SWRConfig
          value={{
            revalidateOnFocus: false,
            revalidateOnReconnect: false,
            focusThrottleInterval: 0,
            fetcher: (...args) => fetch(...args).then((res) => res.json()),
          }}
        >
          <Router>
            <div tw="flex min-h-screen px-0 lg:px-12 xl:px-12">
              <div tw="hidden md:block w-2/12 md:w-2/12 xl:w-3/12">
                <Sidebar />
              </div>
              <div tw="w-full md:w-8/12 xl:w-6/12 border-solid border-0 border-l border-r border-gray-300">
                <Switch>
                  <Route path="/admin/chats/:id/statistics">
                    <StatisticsPage />
                  </Route>
                  <Route path="/admin/chats/:id/scheme">
                    <SchemePage />
                  </Route>
                  <Route path="/admin/chats/:id/template">
                    <TemplatePage />
                  </Route>
                  <Route path="/admin/chats/:id/logs">
                    <LogsPage />
                  </Route>
                  <Route path="/admin/chats/:id/banned">
                    <BannedPage />
                  </Route>
                  <Route path="/admin/chats/:id/permissions">
                    <PermissionsPage />
                  </Route>
                  <Route path="/admin/chats/:id/properties">
                    <PropertiesPage />
                  </Route>
                  <Route path="/admin/chats/:id/custom">
                    <CustomPage />
                  </Route>
                </Switch>
              </div>
              <div tw="hidden md:block w-2/12 md:w-2/12 xl:w-3/12">
                <Chats />
              </div>
            </div>
          </Router>
        </SWRConfig>
      </Provider>
    </React.StrictMode>
  );
};

ReactDOM.render(<App />, document.getElementById("app"));
