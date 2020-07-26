import "../styles/admin.scss";

import React from "react";
import ReactDOM from "react-dom";
import "twin.macro";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import thunkMiddleware from "redux-thunk";
import reduxLogger from "redux-logger";

import { Sidebar, ChatList } from "./admin/components";
import Statistics from "./admin/pages/Statistics";

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
        <div tw="flex min-h-screen px-0 lg:px-12 xl:px-12">
          <div tw="w-2/12 md:w-2/12 xl:w-3/12">
            <Sidebar />
          </div>
          <div tw="w-10/12 md:w-8/12 xl:w-6/12 border-solid border-0 border-l border-r border-gray-300">
            <Statistics />
          </div>
          <div tw="hidden md:block w-2/12 md:w-2/12 xl:w-3/12">
            <ChatList />
          </div>
        </div>
      </Provider>
    </React.StrictMode>
  );
};

ReactDOM.render(<App />, document.getElementById("app"));
