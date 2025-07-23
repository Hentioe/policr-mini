import { createStore } from "solid-js/store";

type State = {
  page: Page;
  currentChat?: ServerData.Chat;
};

const DEFAULT_PAGE: Page = "dashboard";

const [store, setStore] = createStore<State>({
  page: DEFAULT_PAGE,
});

export function setPage(page: Page) {
  setStore("page", page);
}

export function setCurrentChat(chat: ServerData.Chat | undefined) {
  setStore("currentChat", chat);
}

export default store;
