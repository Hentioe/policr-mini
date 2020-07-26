import "../styles/admin.scss";

import React from "react";
import ReactDOM from "react-dom";
import "twin.macro";

import { Nav, ChatList } from "./admin/components";
import Statistics from "./admin/pages/Statistics";

const App = () => {
  return (
    <React.StrictMode>
      <div tw="flex h-screen px-0 lg:px-24 xl:px-12">
        <div tw="w-2/12 md:w-2/12 xl:w-3/12">
          <Nav />
        </div>
        <div tw="w-10/12 md:w-8/12 xl:w-6/12 border-solid border-0 border-l border-r border-gray-300">
          <Statistics />
        </div>
        <div tw="hidden md:block w-2/12 md:w-2/12 xl:w-3/12">
          <ChatList />
        </div>
      </div>
    </React.StrictMode>
  );
};

ReactDOM.render(<App />, document.getElementById("app"));
