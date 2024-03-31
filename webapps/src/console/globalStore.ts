import { createStore } from "solid-js/store";

export type Chat = {
  id: number;
  title: string;
  description?: string;
};

export type PageId =
  | "dashboard"
  | "scheme"
  | "custom"
  | "welcome"
  | "verifications"
  | "operations"
  | "permissions";

export type Store = {
  drawerEl?: HTMLDivElement;
  drawerOpen?: boolean;
  currentChat?: Chat;
  currentPage?: PageId;
};

const [store, setStore] = createStore<Store>();

export function useGlobalStore() {
  const draw = () => {
    if (store.drawerEl != null) {
      if (drawPosition() === "relative") {
        // 如果相对布局（非移动设备），不支持滑动。
        return;
      }

      const currentLeft = store.drawerEl.style.left;
      const isOpen = currentLeft === "0px";
      store.drawerEl.style.left = isOpen ? "-16rem" : "0px";

      setStore({ drawerOpen: !isOpen });
    }
  };

  const drawPosition = (): string | undefined => {
    return store.drawerEl?.computedStyleMap().get("position")?.toString();
  };

  const setDrawerEl = (el: HTMLDivElement) => {
    setStore({ drawerEl: el });
  };

  const setCurrentChat = (chat: Chat) => setStore({ currentChat: chat });
  const setCurrentPage = (pageId: PageId) => setStore({ currentPage: pageId });

  return { store, draw, drawPosition, setDrawerEl, setCurrentChat, setCurrentPage };
}
