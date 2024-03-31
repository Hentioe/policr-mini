import { onMount } from "solid-js";
import { useGlobalStore } from "../globalStore";
import { useTranslation } from "../i18n";
import { GeneralFrameBox } from "../layouts/Frame";

export default () => {
  const t = useTranslation();
  const { setCurrentPage } = useGlobalStore();

  onMount(() => {
    setCurrentPage("welcome");
  });

  return (
    <GeneralFrameBox>
      {t("pages.welcome")}
    </GeneralFrameBox>
  );
};
