import { onMount } from "solid-js";
import { PageBase } from "../layouts";
import { setPage } from "../state/global";
import { setTitle } from "../state/meta";

export default () => {
  onMount(() => {
    setTitle("仪表盘");
    setPage("dashboard");
  });

  return (
    <PageBase>
      示例页面。
    </PageBase>
  );
};
