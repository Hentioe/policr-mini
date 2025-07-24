import { onMount } from "solid-js";
import { PageBase } from "../../layouts";
import { setCurrentPage } from "../../state/global";
import { setTitle } from "../../state/meta";

export default () => {
  onMount(() => {
    setCurrentPage("stats");
    setTitle("统计");
  });

  return (
    <PageBase>
      <p>统计页面。</p>
    </PageBase>
  );
};
