import { onMount } from "solid-js";
import { PageBase } from "../../layouts";
import { setCurrentPage } from "../../state/global";
import { setTitle } from "../../state/meta";

export default () => {
  onMount(() => {
    setCurrentPage("histories");
    setTitle("历史");
  });

  return (
    <PageBase>
      <p>历史页面。</p>
    </PageBase>
  );
};
