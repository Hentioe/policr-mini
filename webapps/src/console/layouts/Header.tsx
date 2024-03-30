import { useGlobalStore } from "../globalStore";

export default () => {
  const { store } = useGlobalStore();

  return (
    <header tw="p-2 lg:p-4 border-b border-black/10">
      {store.currentPage}
    </header>
  );
};
