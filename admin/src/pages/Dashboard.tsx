import { useQuery } from "@tanstack/solid-query";
import { onMount } from "solid-js";
import { getProfile } from "../api";
import { PageBase } from "../layouts";
import { setTitle } from "../state/meta";

export default () => {
  const profileQuery = useQuery(() => ({
    queryKey: ["profile"],
    queryFn: () => getProfile(),
  }));

  onMount(() => {
    setTitle("仪表盘");
  });

  return (
    <PageBase>
      您的用户名是：{profileQuery.data?.success && profileQuery.data.payload.username}
    </PageBase>
  );
};
