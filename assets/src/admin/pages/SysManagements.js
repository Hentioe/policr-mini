import React from "react";
import "twin.macro";
import useSWR from "swr";

import {
  PageHeader,
  NotImplemented,
  PageLoading,
  PageReLoading,
} from "../components";

const endpoint = "/admin/api/chats/list";

export default () => {
  const { data, error } = useSWR(endpoint);

  const isLoaded = () => !error && data;

  return (
    <>
      <PageHeader title="批量管理" />
      {isLoaded() ? (
        <NotImplemented />
      ) : error ? (
        <PageReLoading />
      ) : (
        <PageLoading />
      )}
    </>
  );
};
