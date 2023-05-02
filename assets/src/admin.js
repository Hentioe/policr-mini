import "../styles/admin.scss";
import "react-toastify/dist/ReactToastify.css";

import "twin.macro";
import React from "react";
import { createRoot } from "react-dom/client";
import { Provider, useSelector } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import reduxLogger from "redux-logger";
import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import { SWRConfig } from "swr";
import { ToastContainer } from "react-toastify";
import { HelmetProvider } from "react-helmet-async";

import readonlyBgSvg from "../static/svg/readonly_bg.svg";
import { getFetcher } from "./admin/helper";
import { Sidebar, Chats } from "./admin/components";
import {
  StatisticsPage,
  SchemePage,
  TemplatePage,
  VerificationsPage,
  OperationsPage,
  PermissionsPage,
  PropertiesPage,
  CustomPage,
  SysProfilePage,
  SysManagementsPage,
  SysTasksPage,
  SysTerminalPage,
  SysThirdPartiesPage,
  SysTermsPage,
  SysSponsorshipPage,
} from "./admin/pages";

import Reducers from "./admin/reducers";

const DEBUG = process.env.NODE_ENV == "development";
const middlewares = [DEBUG && reduxLogger].filter(Boolean);

const store = configureStore({
  reducer: Reducers,
  middleware: middlewares,
});

const RootBox = ({ children }) => {
  const readonlyState = useSelector((state) => state.readonly);

  return (
    <div
      tw="flex px-0 lg:px-12 xl:px-12"
      style={{
        background: readonlyState.shown && `url(${readonlyBgSvg})`,
      }}
    >
      {children}
    </div>
  );
};

const App = () => {
  return (
    <React.StrictMode>
      <Provider store={store}>
        <HelmetProvider>
          <SWRConfig
            value={{
              revalidateOnFocus: false,
              revalidateOnReconnect: false,
              focusThrottleInterval: 0,
              fetcher: getFetcher,
            }}
          >
            <Router>
              <RootBox>
                <div tw="hidden md:block w-2/12 md:w-2/12 xl:w-3/12">
                  <Sidebar />
                </div>
                <div tw="w-full min-h-screen flex flex-col md:w-8/12 xl:w-6/12 border-solid border-0 border-l border-r border-gray-300">
                  <Routes>
                    <Route
                      path="/admin/chats/:id/statistics"
                      element={<StatisticsPage />}
                    />
                    <Route
                      path="/admin/chats/:id/scheme"
                      element={<SchemePage />}
                    />

                    <Route
                      path="/admin/chats/:id/template"
                      element={<TemplatePage />}
                    />
                    <Route
                      path="/admin/chats/:id/verifications"
                      element={<VerificationsPage />}
                    />
                    <Route
                      path="/admin/chats/:id/operations"
                      element={<OperationsPage />}
                    />
                    <Route
                      path="/admin/chats/:id/permissions"
                      element={<PermissionsPage />}
                    />
                    <Route
                      path="/admin/chats/:id/properties"
                      element={<PropertiesPage />}
                    />
                    <Route
                      path="/admin/chats/:id/custom"
                      element={<CustomPage />}
                    />
                    <Route
                      path="/admin/sys/managements"
                      element={<SysManagementsPage />}
                    />
                    <Route
                      path="/admin/sys/profile"
                      element={<SysProfilePage />}
                    />
                    <Route path="/admin/sys/tasks" element={<SysTasksPage />} />
                    <Route path="/admin/sys/terms" element={<SysTermsPage />} />
                    <Route
                      path="/admin/sys/terminal"
                      element={<SysTerminalPage />}
                    />
                    <Route
                      path="/admin/sys/third_parties"
                      element={<SysThirdPartiesPage />}
                    />
                    <Route
                      path="/admin/sys/sponsorship"
                      element={<SysSponsorshipPage />}
                    />
                  </Routes>
                </div>
                <div tw="hidden md:block w-2/12 md:w-2/12 xl:w-3/12">
                  <Chats />
                </div>
              </RootBox>
              <ToastContainer
                position="bottom-center"
                autoClose={2500}
                hideProgressBar={false}
                newestOnTop={false}
                closeOnClick
                rtl={false}
                pauseOnFocusLoss
                draggable
                pauseOnHover
              />
            </Router>
          </SWRConfig>
        </HelmetProvider>
      </Provider>
    </React.StrictMode>
  );
};

createRoot(document.getElementById("app")).render(<App />);
