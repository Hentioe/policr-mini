import { createStore } from "solid-js/store";

type State = {
  page: Page;
};

const DEFAULT_PAGE: Page = "dashboard";

const [store, setStore] = createStore<State>({
  page: DEFAULT_PAGE,
});

export function setPage(page: Page) {
  setStore("page", page);
}

export default store;
