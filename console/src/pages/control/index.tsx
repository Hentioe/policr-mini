import { onMount } from "solid-js";
import { PageBase } from "../../layouts";
import { setCurrentPage } from "../../state/global";
import { setTitle } from "../../state/meta";

export default () => {
  onMount(() => {
    setCurrentPage("control");
    setTitle("控制");
  });

  return (
    <PageBase>
      <p>控制页面。</p>
    </PageBase>
  );
};
