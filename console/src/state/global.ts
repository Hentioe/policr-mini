import { createStore } from "solid-js/store";

type State = {
  currentPage: Page;
  currentChatId: number | null;
  currentChatTitle: string | null;
  emptyChatList?: boolean;
  drawerIsOpen: boolean;
};

const DEFAULT_PAGE: Page = "stats";

const [store, setStore] = createStore<State>({
  currentPage: DEFAULT_PAGE,
  drawerIsOpen: false,
  currentChatId: null,
  currentChatTitle: null,
});

export function setCurrentPage(page: Page) {
  setStore("currentPage", page);
}

export function setCurrentChat(chat: ServerData.Chat) {
  setStore("currentChatId", chat.id);
  setStore("currentChatTitle", chat.title);
}

export function toggleDrawer() {
  setStore("drawerIsOpen", !store.drawerIsOpen);
}

export function setEmptyChatList(empty: boolean) {
  setStore("emptyChatList", empty);
}

export default store;
