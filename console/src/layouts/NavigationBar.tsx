import { Icon } from "@iconify-icon/solid";
import { destructure } from "@solid-primitives/destructure";
import { useNavigate } from "@solidjs/router";
import classNames from "classnames";
import { globalState } from "../state";

export default () => {
  return (
    <nav class="fixed bottom-0 left-0 right-0 h-navigation z-50 bg-white/40 backdrop-blur-md border-t border-zinc-200 flex items-center justify-around">
      <PageLink page="stats" icon="iconoir:stats-up-square-solid" text="统计" />
      <PageLink page="control" icon="ant-design:control-filled" text="控制" />
      <PageLink page="customize" icon="fa7-solid:pencil-square" text="自定义" />
      <PageLink page="histories" icon="uim:history" text="历史" />
    </nav>
  );
};

const PageLink = (
  props: { page: Page; icon: string; text: string },
) => {
  const navigate = useNavigate();
  const { currentPage } = destructure(globalState);

  const handleClick = () => {
    navigate(`/${props.page}`);
  };

  return (
    <div
      onClick={handleClick}
      class={classNames([
        "h-full w-full py-[0.25rem] flex flex-col justify-between items-center text-gray-600/70",
        {
          "text-zinc-700/70 bg-blue-100/50!": currentPage() === props.page,
        },
      ])}
    >
      <Icon icon={props.icon} class="text-[2rem] h-[2rem]" />
      <p class="text-sm">{props.text}</p>
    </div>
  );
};
