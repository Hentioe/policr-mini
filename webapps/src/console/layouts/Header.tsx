import { useGlobalStore } from "../globalStore";
import { useTranslation } from "../i18n";

export default () => {
  const t = useTranslation();
  const { store } = useGlobalStore();

  return (
    <header tw="p-2 lg:p-4 border-b border-black/10">
      {t(`pages.${store.currentPage || "unknown"}`)}
    </header>
  );
};
