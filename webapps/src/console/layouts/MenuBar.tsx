import { FiMoreHorizontal } from "solid-icons/fi";
import { Show } from "solid-js";
import tw, { styled } from "twin.macro";

type ActiveProp = {
  active?: boolean;
};

const MenuLinkRoot = styled.div((ps: ActiveProp) => [
  tw`py-3 lg:py-4 cursor-pointer`,
  ps.active ? tw`bg-indigo-500/20` : tw`hover:bg-indigo-500/10`,
]);

export default () => {
  const MenuLink = (props: { title: string; description?: string } & ActiveProp) => {
    return (
      <MenuLinkRoot active={props.active}>
        <div tw="ml-[2rem] select-none tracking-wide">
          <p tw="font-medium">{props.title}</p>
          <Show when={props.description}>
            <p tw="mt-2 text-xs lg:text-[0.8rem] text-zinc-600 mr-[2rem]">
              {props.description}
            </p>
          </Show>
        </div>
      </MenuLinkRoot>
    );
  };

  return (
    <div tw="flex flex-col w-full bg-white/20 pt-4">
      <header tw="flex justify-between px-2 text-white font-bold">
        <span tw="flex items-center justify-center truncate bg-zinc-800/20 px-3 w-[10rem] h-[1.8rem] rounded-xl">
          群标题
        </span>
        <span tw="flex items-center justify-center bg-zinc-800/20 font-bold rounded-full w-[1.8rem] h-[1.8rem] hover:shadow cursor-pointer">
          <FiMoreHorizontal size="1.5rem" />
        </span>
      </header>
      <div tw="p-2">
        <p tw="p-2 w-full bg-white/30 text-zinc-700 text-xs rounded tracking-wider">
          我是群描述，这是一个静态的虚拟群组，用于开发和测试效果。再写一点，增加一些内容。
        </p>
      </div>
      <main tw="mt-2 flex-1 overflow-y-auto" class="hidden-scrollbar">
        <div>
          <MenuLink active={true} title="仪表盘" description="详细的群组统计数据" />
          <MenuLink title="当前方案" description="查看或修改验证模型" />
          <MenuLink title="定制验证" description="自定义验证问答列表" />
          <MenuLink title="欢迎消息" description="新成员加入的欢迎内容" />
          <MenuLink title="验证历史" description="所有可查询的验证记录" />
          <MenuLink title="操作历史" description="所有可查询的操作记录" />
          <MenuLink title="控制权限" description="管理具有控制权限的成员" />
        </div>
      </main>
    </div>
  );
};
