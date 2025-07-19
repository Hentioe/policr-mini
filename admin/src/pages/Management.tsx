import { Icon } from "@iconify-icon/solid";
import { For, JSX, onMount } from "solid-js";
import { PageBase } from "../layouts";
import { setPage } from "../state/global";
import { setTitle } from "../state/meta";

const CHATS: ServerData.Chat[] = Array.from({ length: 15 }, (_, i) => ({
  id: 1000000000000 + i,
  title: `你好${i + 1}`,
  username: `@username${i + 1}`,
  createdAt: `2025-07-19 14:0${i % 10}${i % 10}`,
}));

export default () => {
  onMount(() => {
    setTitle("批量管理");
    setPage("management");
  });

  return (
    <PageBase>
      <div class="w-9/12 mx-auto flex items-center border border-zinc-200 shadow hover:shadow-strong-light rounded-full">
        <Icon icon="material-symbols:search" class="w-[4rem] text-[2rem] text-zinc-400" />
        <input
          placeholder="输入群标题、群描述中的关键字"
          type="text"
          class="flex-1 h-[3.25rem] outline-0 tracking-wider"
        />
      </div>
      <div class="mt-[2rem] rounded-xl shadow-strong overflow-hidden">
        <table class="w-full">
          <thead class="bg-gray-100 tracking-wide">
            <tr class="*:px-[1rem] *:py-[1rem] *:text-left *:text-gray-700">
              <th>群标题</th>
              <th>USERNAME</th>
              <th>加入时间</th>
              <th class="text-right!">操作</th>
            </tr>
          </thead>
          <tbody class="bg-white *:not-last:border-b *:border-gray-200">
            <For each={CHATS}>
              {(chat) => (
                <tr class="*:px-[1rem] *:py-[0.5rem] *:text-left *:text-gray-700">
                  <td>{chat.title}</td>
                  <td>{chat.username}</td>
                  <td>{chat.createdAt}</td>
                  <td class="text-right!">
                    <ActionButtonList>
                      <ActionButton color="limegreen">
                        同步
                      </ActionButton>
                      <ActionButton color="indianred">
                        退出
                      </ActionButton>
                    </ActionButtonList>
                  </td>
                </tr>
              )}
            </For>
          </tbody>
        </table>
        <div class="bg-gray-100 flex justify-between px-[1rem] py-[0.5rem]">
          <PageButton>
            上一页
          </PageButton>
          <span class="text-gray-500">
            第 1 - 15 条记录
          </span>
          <PageButton>
            下一页
          </PageButton>
        </div>
      </div>
    </PageBase>
  );
};

const PageButton = (props: { children: JSX.Element }) => {
  return (
    <a class="text-blue-500 cursor-pointer">
      {props.children}
    </a>
  );
};

const ActionButtonList = (props: { children: JSX.Element }) => {
  return (
    <div class="flex gap-[0.5rem] justify-end">
      {props.children}
    </div>
  );
};

const ActionButton = (props: { children: JSX.Element; color: string }) => {
  return <button class="cursor-pointer" style={{ color: props.color }}>{props.children}</button>;
};
