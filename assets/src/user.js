import "../styles/user.scss";

import React, { useEffect } from "react";
import ReactDOM from "react-dom";
import { HelmetProvider } from "react-helmet-async";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import thunkMiddleware from "redux-thunk";
import reduxLogger from "redux-logger";
import { useSelector } from "react-redux";
import "twin.macro";
import { BrowserRouter as Router, Switch, Route } from "react-router-dom";

import { IndexPage, TermsPage, LoginPage } from "./user/pages";
import { Header, Footer, ModalContainer } from "./user/components";
import Reducers from "./user/reducers";

const DEBUG = process.env.NODE_ENV == "development";

const middlewares = [thunkMiddleware, DEBUG && reduxLogger].filter(Boolean);

const store = configureStore({
  reducer: Reducers,
  middleware: middlewares,
});

// 首页参考：https://smartlogic.io/
const App = () => {
  useEffect(() => {
    const $loading = document.getElementById("loading-wrapper");
    if ($loading) $loading.outerHTML = "";
  }, []);

  return (
    <React.StrictMode>
      <Provider store={store}>
        <HelmetProvider>
          <Root />
        </HelmetProvider>
      </Provider>
    </React.StrictMode>
  );
};

const Root = () => {
  const modalState = useSelector((state) => state.modal);

  return (
    <div tw="relative min-h-screen">
      <div
        tw="fixed w-full h-full"
        style={{
          background: modalState.isOpen ? "rgba(0, 0, 0, 0.7)" : "transparent",
          zIndex: modalState.isOpen ? 49 : -1,
        }}
      >
        <div tw="absolute w-full h-screen">
          {(modalState.isOpen && (
            <ModalContainer>{modalState.content}</ModalContainer>
          )) ||
            undefined}
        </div>
      </div>

      <div tw="min-h-screen flex flex-col">
        <Header />

        <Router>
          <Switch>
            <Route path="/terms">
              <TermsPage />
            </Route>
            <Route path="/login">
              <LoginPage />
            </Route>
            <Route>
              <IndexPage path="/" />
            </Route>
          </Switch>
        </Router>
        <Footer />
      </div>
    </div>
  );
};

let renderDelay = 600;
if (DEBUG) renderDelay = 0;

setTimeout(() => {
  ReactDOM.render(<App />, document.getElementById("app"));
}, renderDelay);
