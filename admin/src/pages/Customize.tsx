import { onMount } from "solid-js";
import { PageBase } from "../layouts";
import { setPage } from "../state/global";
import { setTitle } from "../state/meta";

export default () => {
  onMount(() => {
    setTitle("全局调整");
    setPage("customize");
  });

  return (
    <PageBase>
      全局调整页面。
    </PageBase>
  );
};
