import "../styles/user.scss";

import React, { useEffect } from "react";
import ReactDOM from "react-dom";
import IndexPage from "./user/pages/Index";
import { HelmetProvider } from "react-helmet-async";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import thunkMiddleware from "redux-thunk";
import reduxLogger from "redux-logger";
import { useSelector } from "react-redux";
import "twin.macro";

import { Header, Footer, Modal } from "./user/components";
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
    <div
      tw="relative h-full"
      // style={{
      //   position: modalState.isOpen ? "fixed" : "relative",
      // }}
    >
      <div
        tw="absolute w-full min-h-full"
        style={{
          background: modalState.isOpen ? "rgba(0, 0, 0, 0.7)" : "transparent",
          zIndex: modalState.isOpen ? 49 : -1,
        }}
      >
        <div tw="absolute w-full h-screen">
          {modalState.isOpen ? (
            <Modal title={modalState.title}>{modalState.content}</Modal>
          ) : undefined}
        </div>
      </div>

      <div>
        <Header />
        <IndexPage />
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
