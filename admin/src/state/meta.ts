import { createStore } from "solid-js/store";

type State = {
  title?: string;
};

const baseTitle = "Mini Admin V2";

const [store, setStore] = createStore<State>({
  title: baseTitle,
});

export function setTitle(title?: string) {
  if (title) {
    setStore("title", title + " - " + baseTitle);
  } else {
    setStore("title", baseTitle);
  }
}

export default store;
