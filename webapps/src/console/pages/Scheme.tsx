import { onMount } from "solid-js";
import { useGlobalStore } from "../globalStore";
import { GeneralFrameBox } from "../layouts/Frame";

export default () => {
  const { setCurrentPage } = useGlobalStore();

  onMount(() => {
    setCurrentPage("scheme");
  });

  return (
    <GeneralFrameBox>
      当前方案
    </GeneralFrameBox>
  );
};
