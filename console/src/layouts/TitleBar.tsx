import { Icon } from "@iconify-icon/solid";
import { destructure } from "@solid-primitives/destructure";
import { globalState, metaState } from "../state";
import { toggleDrawer } from "../state/global";

export default () => {
  const { currentChatTitle } = destructure(globalState);
  const { title } = destructure(metaState);

  const handleToggleDrawer = () => {
    toggleDrawer();
  };

  return (
    <header class="fixed top-0 w-full h-header bg-white/40 backdrop-blur-md shadow flex items-center justify-between pr-edge">
      <div onClick={handleToggleDrawer} class="px-edge h-full flex items-center">
        <Icon icon="mdi:menu" class="text-[2rem] w-[2rem]" />
      </div>
      <h1 class="text-lg font-bold text-center px-[1rem] line-clamp-1">
        {title()}
        {currentChatTitle() && ` / ${currentChatTitle()}`}
      </h1>
      <span class="w-[2rem]" />
    </header>
  );
};
