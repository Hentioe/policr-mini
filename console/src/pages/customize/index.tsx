import { onMount } from "solid-js";
import { PageBase } from "../../layouts";
import { setCurrentPage } from "../../state/global";
import { setTitle } from "../../state/meta";

export default () => {
  onMount(() => {
    setCurrentPage("customize");
    setTitle("自定义");
  });

  return (
    <PageBase>
      <p>自定义页面。</p>
    </PageBase>
  );
};
