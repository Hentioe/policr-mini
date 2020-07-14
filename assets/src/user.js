import "../styles/user.scss";

import React, { useEffect } from "react";
import ReactDOM from "react-dom";
import IndexPage from "./user/pages/Index";
import { Navbar } from "./user/components";

const DEBUG = process.env.NODE_ENV == "development";

// 首页参考：https://smartlogic.io/
const App = () => {
  useEffect(() => {
    const $loading = document.getElementById("loading-wrapper");
    if ($loading) $loading.outerHTML = "";
  }, []);

  return (
    <React.StrictMode>
      <div>
        <Navbar />
        <IndexPage />
      </div>
    </React.StrictMode>
  );
};

let renderDelay = 600;
if (DEBUG) renderDelay = 0;

setTimeout(() => {
  ReactDOM.render(<App />, document.getElementById("app"));
}, renderDelay);
