import { createStore } from "solid-js/store";

type State = {
  title: string | null;
  pageTitle?: string;
};

const baseTitle = "Mini Console (Mini Apps)";

const [store, setStore] = createStore<State>({
  title: null,
});

export function setTitle(title: string) {
  setStore("title", title);
  setStore("pageTitle", title + " - " + baseTitle);
}

export default store;
