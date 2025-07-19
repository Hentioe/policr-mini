import { metaState } from "../state";

export default () => {
  return (
    <header class="border-b border-zinc-300/70 py-[0.5rem]">
      <h1 class="text-3xl font-bold text-zinc-800 text-center tracking-wide">
        {metaState.title}
      </h1>
    </header>
  );
};
