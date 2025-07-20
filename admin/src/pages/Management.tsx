import { Icon } from "@iconify-icon/solid";
import { useQuery } from "@tanstack/solid-query";
import classNames from "classnames";
import { format } from "date-fns";
import { createEffect, createSignal, For, JSX, onMount } from "solid-js";
import { getManagement } from "../api";
import { ActionButton } from "../components";
import { PageBase } from "../layouts";
import { setPage } from "../state/global";
import { setTitle } from "../state/meta";

export default () => {
  const [currentPage, setCurrentPage] = createSignal(1);
  const [pageSize, setPageSize] = createSignal(10);
  const [chatsTotal, setChatsTotal] = createSignal(0);
  const managementQuery = useQuery(() => ({
    queryKey: ["management"],
    queryFn: getManagement,
  }));

  createEffect(() => {
    if (managementQuery.data?.success) {
      const data = managementQuery.data.payload;
      setCurrentPage(data.page);
      setPageSize(data.pageSize);
      setChatsTotal(data.chatsTotal);
    }
  });

  onMount(() => {
    setTitle("批量管理");
    setPage("management");
  });

  return (
    <PageBase>
      <div class="w-9/12 my-[1rem] mx-auto flex items-center border border-zinc-200 shadow hover:shadow-strong-light rounded-full hover:translate-y-[-2px] transition-all">
        <Icon icon="fluent-color:search-sparkle-16" class="w-[4rem] text-[2rem] text-zinc-400" />
        <input
          placeholder="输入群标题、群描述中的关键字"
          type="text"
          class="flex-1 h-[3.25rem] outline-0 tracking-wider"
        />
      </div>
      <div class="my-[1rem] p-[1rem] bg-blue-100/40 text-gray-600 rounded-xl flex justify-between items-center border-l-4 border-l-blue-400 card-edge">
        <p>
          显示第 {(currentPage() - 1) * pageSize() + 1} - {currentPage() * pageSize()} 条记录，共 {chatsTotal()} 条
        </p>
        <div>
          <ActionButton icon="material-symbols:refresh">
            刷新
          </ActionButton>
        </div>
      </div>
      <table class="w-full card-edge shadow-strong">
        <thead class="tracking-wide">
          <tr class="*:px-[1rem] *:py-[1rem] *:bg-gray-100 *:text-left *:text-gray-700">
            <th class="w-4/12">群详情</th>
            <th class="w-3/12 text-center!">群链接</th>
            <th class="w-3/12 text-center!">加入时间</th>
            <th class="w-2/12 text-right!">操作</th>
          </tr>
        </thead>
        <tbody class="bg-blue-500 *:bg-white *:not-last:border-b *:border-gray-200">
          <For each={managementQuery.data?.success && managementQuery.data.payload.chats || []}>
            {(chat) => (
              <tr class="*:px-[1rem] *:py-[0.5rem] *:text-left *:text-gray-700 hover:bg-blue-50 hover:translate-x-1 transition-all">
                <td>
                  <p class="font-bold tracking-wide line-clamp-1">
                    {chat.title}
                  </p>
                  <p class="mt-1 text-sm text-gray-600 tracking-wider line-clamp-1">
                    {chat.description || "无描述"}
                  </p>
                </td>
                <td class="text-center!">
                  <ChatLink username={chat.username} />
                </td>
                <td class="text-center!">
                  <span class="text-gray-600 bg-zinc-100 px-2 py-1 rounded-lg">
                    {format(chat.createdAt, "yyyy-MM-dd HH:mm:ss")}
                  </span>
                </td>
                <td class="text-right!">
                  <ActionButtonList>
                    <ActionButton size="sm" variant="info">
                      同步
                    </ActionButton>
                    <ActionButton size="sm" variant="danger">
                      退出
                    </ActionButton>
                  </ActionButtonList>
                </td>
              </tr>
            )}
          </For>
        </tbody>
      </table>
      <div class="mt-[2rem] flex justify-between gap-[0.5rem]">
        <PageButton>
          上一页
        </PageButton>
        <div class="flex gap-[0.5rem]">
          <PageButton current>1</PageButton>
          <PageButton>2</PageButton>
          <PageButton>3</PageButton>
          <PageButton>4</PageButton>
          <PageButton>5</PageButton>
        </div>
        <PageButton>
          下一页
        </PageButton>
      </div>
    </PageBase>
  );
};

const ChatLink = (props: { username?: string }) => {
  return (
    <>
      {props.username
        ? (
          <a href={`https://t.me/${props.username}`} class="text-zinc-600 hover:underline" target="_blank">
            @{props.username}
          </a>
        )
        : <span>无</span>}
    </>
  );
};

const PageButton = (props: { children: JSX.Element; current?: boolean }) => {
  return (
    <a
      class={classNames([
        "px-4 py-2 bg-white card-edge shadow-strong cursor-pointer",
        {
          "bg-blue-600! text-zinc-50": props.current,
        },
      ])}
    >
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
