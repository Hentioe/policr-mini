import { createStore } from "solid-js/store";

type State = {
  title?: string;
  pageTitle?: string;
};

const baseTitle = "Mini Admin V2";

const [store, setStore] = createStore<State>({
  title: baseTitle,
});

export function setTitle(title: string) {
  setStore("title", title);
  setStore("pageTitle", title + " - " + baseTitle);
}

export default store;
