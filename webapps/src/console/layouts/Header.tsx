import { VsThreeBars } from "solid-icons/vs";
import { useGlobalStore } from "../globalStore";
import { useTranslation } from "../i18n";

export default () => {
  const t = useTranslation();
  const { draw } = useGlobalStore();
  const { store } = useGlobalStore();

  const handleDrawOpen = (e: Event) => {
    // 阻止冒泡，避免因 Content 组件的点击事件关闭抽屉
    e.preventDefault();
    e.stopPropagation();
    draw();
  };

  return (
    <header tw="p-2 lg:p-4 border-b border-black/10 flex justify-center items-center">
      <div tw="block lg:hidden w-[1.5rem]">
        <VsThreeBars size="1.5rem" tw="text-zinc-800" onClick={handleDrawOpen} />
      </div>
      <p tw="flex-1 text-zinc-800 text-lg lg:text-xl font-medium text-center">
        {t(`pages.${store.currentPage || "unknown"}`)}
      </p>
      <div tw="w-[1.5rem]" />
    </header>
  );
};
