import { onMount } from "solid-js";
import { useGlobalStore } from "../globalStore";
import { GeneralFrameBox } from "../layouts/Frame";

export default () => {
  const { setCurrentPage } = useGlobalStore();

  onMount(() => {
    setCurrentPage("dashboard");
  });

  return (
    <GeneralFrameBox>
      仪表盘
    </GeneralFrameBox>
  );
};
