import "../styles/admin.scss";

import React from "react";
import ReactDOM from "react-dom";
import "twin.macro";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import thunkMiddleware from "redux-thunk";
import reduxLogger from "redux-logger";
import { BrowserRouter as Router, Switch, Route } from "react-router-dom";

import { Sidebar, Chats } from "./admin/components";
import { NotImplementedPage } from "./admin/pages";

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
        <Router>
          <div tw="flex min-h-screen px-0 lg:px-12 xl:px-12">
            <div tw="w-2/12 md:w-2/12 xl:w-3/12">
              <Sidebar />
            </div>
            <div tw="w-10/12 md:w-8/12 xl:w-6/12 border-solid border-0 border-l border-r border-gray-300">
              <Switch>
                <Route path="/admin/chats/:id/statistics">
                  <NotImplementedPage />
                </Route>
                <Route path="/admin/chats/:id/scheme">
                  <NotImplementedPage />
                </Route>
                <Route path="/admin/chats/:id/template">
                  <NotImplementedPage />
                </Route>
                <Route path="/admin/chats/:id/logs">
                  <NotImplementedPage />
                </Route>
                <Route path="/admin/chats/:id/banned">
                  <NotImplementedPage />
                </Route>
                <Route path="/admin/chats/:id/permissions">
                  <NotImplementedPage />
                </Route>
                <Route path="/admin/chats/:id/properties">
                  <NotImplementedPage />
                </Route>
                <Route path="/admin/chats/:id/custom">
                  <NotImplementedPage />
                </Route>
              </Switch>
            </div>
            <div tw="hidden md:block w-2/12 md:w-2/12 xl:w-3/12">
              <Chats />
            </div>
          </div>
        </Router>
      </Provider>
    </React.StrictMode>
  );
};

ReactDOM.render(<App />, document.getElementById("app"));
