import React from "react";
import { Helmet } from "react-helmet";

export default ({ children: children }) => {
  return (
    <Helmet>
      <title>{`${children} - Policr Mini`}</title>
    </Helmet>
  );
};
