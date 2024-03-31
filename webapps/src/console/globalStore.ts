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
  currentChat?: Chat;
  currentPage?: PageId;
};

const [store, setStore] = createStore<Store>();

export function useGlobalStore() {
  const draw = () => {
    if (store.drawerEl != null) {
      const currentLeft = store.drawerEl.style.left;
      store.drawerEl.style.left = currentLeft === "0px" ? "-16rem" : "0px";
    }
  };

  const setDrawerEl = (el: HTMLDivElement) => {
    setStore({ drawerEl: el });
  };

  const setCurrentChat = (chat: Chat) => setStore({ currentChat: chat });
  const setCurrentPage = (pageId: PageId) => setStore({ currentPage: pageId });

  return { store, draw, setDrawerEl, setCurrentChat, setCurrentPage };
}
