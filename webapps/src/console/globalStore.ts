import { createStore } from "solid-js/store";

export type Store = {
  drawerEl?: HTMLDivElement;
};

const [store, setStore] = createStore<Store>();

export function useGlobalStore() {
  const draw = () => {
    if (store.drawerEl != null) {
      const currentLeft = store.drawerEl.style.left;
      store.drawerEl.style.left = currentLeft === "0px" ? "-20rem" : "0px";
    }
  };

  const setDrawerEl = (el: HTMLDivElement) => {
    setStore({ drawerEl: el });
  };

  return { store, draw, setDrawerEl };
}

export default store;
