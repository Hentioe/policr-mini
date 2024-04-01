import { A, useLocation } from "@solidjs/router";
import { FiMoreHorizontal } from "solid-icons/fi";
import { createEffect, Show } from "solid-js";
import tw, { styled } from "twin.macro";
import { PageId, useGlobalStore } from "../globalStore";
import { useTranslation } from "../i18n";

type ActiveProp = {
  active?: boolean;
};

const MenuLinkRoot = styled(A)((ps: ActiveProp) => [
  tw`block py-3 lg:py-4 cursor-pointer`,
  ps.active ? tw`bg-indigo-500/20` : tw`hover:bg-indigo-500/10`,
]);

export default () => {
  const t = useTranslation();
  const location = useLocation();
  const { store, draw } = useGlobalStore();

  createEffect(() => {
    if (location.pathname) {
      draw();
    }
  });

  const MenuLink = (props: { pageId: PageId; description?: string } & ActiveProp) => {
    return (
      <MenuLinkRoot href={`/${store.currentChat?.id}/${props.pageId}`} active={store.currentPage === props.pageId}>
        <div tw="ml-[1.25rem] lg:ml-[2rem] select-none tracking-wide">
          <p tw="font-medium">{t(`pages.${props.pageId}`)}</p>
          <Show when={props.description}>
            <p tw="mt-2 text-xs lg:text-[0.8rem] text-zinc-600 mr-[2rem]">
              {props.description}
            </p>
          </Show>
        </div>
      </MenuLinkRoot>
    );
  };

  return (
    <div tw="flex flex-col w-full bg-white/20 pt-4">
      <header tw="flex justify-between px-2 text-white font-bold">
        <span tw="flex items-center justify-center truncate bg-zinc-800/20 px-3 w-[8rem] lg:w-[10rem] h-[1.8rem] rounded-xl">
          {store.currentChat?.title || "未选择群组"}
        </span>
        <span tw="flex items-center justify-center bg-zinc-800/20 font-bold rounded-full w-[1.8rem] h-[1.8rem] hover:shadow cursor-pointer">
          <FiMoreHorizontal size="1.5rem" />
        </span>
      </header>
      <div tw="p-2">
        <div tw="p-2 bg-white/30 rounded">
          <p tw="w-full text-zinc-600 text-xs tracking-wider line-clamp-5">
            {store.currentChat?.description || "无描述"}
          </p>
        </div>
      </div>
      <main tw="flex-1 overflow-y-auto" class="hidden-scrollbar">
        <div>
          <MenuLink
            pageId="dashboard"
            description="详细的群组统计数据"
          />
          <MenuLink
            pageId="scheme"
            description="查看或修改验证模型"
          />
          <MenuLink
            pageId="custom"
            description="自定义验证问答列表"
          />
          <MenuLink
            pageId="welcome"
            description="新成员加入的欢迎内容"
          />
          <MenuLink
            pageId="verifications"
            description="所有可查询的验证记录"
          />
          <MenuLink
            pageId="operations"
            description="所有可查询的操作记录"
          />
          <MenuLink
            pageId="permissions"
            description="管理具有控制权限的成员"
          />
        </div>
      </main>
    </div>
  );
};
