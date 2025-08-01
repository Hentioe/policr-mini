import { onMount } from "solid-js";
import { PageBase } from "../../layouts";
import { setCurrentPage } from "../../state/global";
import { setTitle } from "../../state/meta";

export default () => {
  onMount(() => {
    setCurrentPage("example");
    setTitle("示例");
  });

  return (
    <PageBase>
      <p>示例页面。</p>
    </PageBase>
  );
};
