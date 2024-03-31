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
    <header tw="border-b border-black/10 flex justify-center items-center">
      <div
        onClick={handleDrawOpen}
        tw="block lg:hidden flex justify-center w-[2.5rem] py-2 lg:py-4 hover:bg-white/20 rounded-full"
      >
        <VsThreeBars size="1.5rem" tw="text-zinc-800" />
      </div>
      <p tw="flex-1 text-zinc-800 text-lg lg:text-xl font-medium text-center">
        {t(`pages.${store.currentPage || "unknown"}`)}
      </p>
      <div tw="w-[2.5rem]" />
    </header>
  );
};
