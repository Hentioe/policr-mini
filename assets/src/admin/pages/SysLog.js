import React from "react";
import { PageHeader, PageLoading, NotImplemented } from "../components";
import useSWR from "swr";
import "twin.macro";

export default () => {
  const { data } = useSWR("/admin/api/logs");

  const isLoaded = () => data;

  return (
    <>
      <PageHeader title="系统日志" />
      {isLoaded() ? <NotImplemented /> : <PageLoading />}
    </>
  );
};
