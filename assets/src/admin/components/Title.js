import React from "react";
import { Helmet } from "react-helmet-async";

export default ({ children: children }) => {
  return (
    <Helmet>
      <title>{`${children} - Mini Admin`}</title>
    </Helmet>
  );
};
