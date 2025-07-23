import { onMount } from "solid-js";
import { PageBase } from "../../layouts";
import { setPage } from "../../state/global";
import { setTitle } from "../../state/meta";

export default () => {
  onMount(() => {
    setPage("dashboard");
    setTitle("示例页面");
  });

  return (
    <PageBase>
      示例页面。
    </PageBase>
  );
};
