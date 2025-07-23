import { metaState } from "../state";

export default () => {
  return (
    <header class="h-title-bar-height border-b border-line flex justify-center items-center">
      <h1 class="text-3xl font-bold text-zinc-700 text-center tracking-wide">
        {metaState.title}
      </h1>
    </header>
  );
};
