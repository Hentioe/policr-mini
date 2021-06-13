import "../styles/user.scss";

import React, { useEffect } from "react";
import ReactDOM from "react-dom";
import IndexPage from "./user/pages/Index";
import { Header, Footer } from "./user/components";
import { HelmetProvider } from "react-helmet-async";

const DEBUG = process.env.NODE_ENV == "development";

// 首页参考：https://smartlogic.io/
const App = () => {
  useEffect(() => {
    const $loading = document.getElementById("loading-wrapper");
    if ($loading) $loading.outerHTML = "";
  }, []);

  return (
    <React.StrictMode>
      <HelmetProvider>
        <div>
          <Header />
          <IndexPage />
          <Footer />
        </div>
      </HelmetProvider>
    </React.StrictMode>
  );
};

let renderDelay = 600;
if (DEBUG) renderDelay = 0;

setTimeout(() => {
  ReactDOM.render(<App />, document.getElementById("app"));
}, renderDelay);
