import { Icon } from "@iconify-icon/solid";
import { useSearchParams } from "@solidjs/router";
import { useQuery } from "@tanstack/solid-query";
import classNames from "classnames";
import { format } from "date-fns";
import { createEffect, createSignal, For, JSX, onMount, Show } from "solid-js";
import { getManagement, leaveChat, syncChat } from "../../api";
import { ActionButton } from "../../components";
import { PageBase } from "../../layouts";
import { setPage } from "../../state/global";
import { setTitle } from "../../state/meta";
import { toaster } from "../../utils";
import ChatLink from "./ChatLink";
import { getPaginationPages } from "./helper";

export default () => {
  const [searchParams, setSearchParams] = useSearchParams<{ page?: string; keywords?: string }>();
  const [pageNum, setPageNum] = createSignal(1);
  const [pageSize, setPageSize] = createSignal(10);
  const [total, setTotal] = createSignal(0);
  const [pageNums, setPageNums] = createSignal<number[]>([]);
  const [editingKeywords, setEditingKeywords] = createSignal(searchParams.keywords || "");
  const [isRefreshing, setIsRefreshing] = createSignal(false);
  const [syncingChats, setSyncingChats] = createSignal<number[]>([]);
  const [leavingChats, setLeavingChats] = createSignal<number[]>([]);
  const managementQuery = useQuery(() => ({
    queryKey: ["management", searchParams.page || 1, searchParams.keywords || ""],
    queryFn: () => getManagement({ page: searchParams.page, keywords: searchParams.keywords }),
  }));

  const handleKeywordsInput = (e: InputEvent) => {
    const input = e.currentTarget as HTMLInputElement;
    setEditingKeywords(input.value);
  };

  const handleKeywordsKeyDown = (e: KeyboardEvent) => {
    if (e.key === "Enter") {
      const keywords = editingKeywords().trim();
      if (keywords !== "") {
        setSearchParams({ keywords, page: 1 });
      } else {
        setSearchParams({ keywords: undefined, page: 1 });
      }
    }
  };

  const handleRefresh = async () => {
    setIsRefreshing(true);
    await managementQuery.refetch();
    setIsRefreshing(false);
    toaster.success({ title: "刷新成功", description: `第 ${pageNum()} 页数据已刷新` });
  };

  const handleSyncChat = async (chat: ServerData.Chat) => {
    setSyncingChats((prev) => [...prev, chat.id]);
    const resp = await syncChat(chat.id);
    setSyncingChats((prev) => prev.filter(id => id !== chat.id));
    if (resp.success) {
      toaster.success({ title: "同步成功", description: `群 ${resp.payload.title} 完成同步` });
      managementQuery.refetch();
    } else {
      let title = "同步失败";
      if (chat.title) {
        title = `群 ${chat.title} ` + title;
      } else {
        title = `群 ${chat.id} ` + title;
      }
      toaster.error({ title: title, description: resp.message });
    }
  };

  const handleLeaveChat = async (chat: ServerData.Chat) => {
    setLeavingChats((prev) => [...prev, chat.id]);
    const resp = await leaveChat(chat.id);
    setLeavingChats((prev) => prev.filter(id => id !== chat.id));
    if (resp.success) {
      toaster.success({ title: "退出成功", description: `群 ${resp.payload.title} 完成退出` });
      managementQuery.refetch();
    } else {
      let title = "退出失败";
      if (chat.title) {
        title = `群 ${chat.title} ` + title;
      } else {
        title = `群 ${chat.id} ` + title;
      }
      toaster.error({ title: title, description: resp.message });
    }
  };

  createEffect(() => {
    if (managementQuery.isLoading) {
      setIsRefreshing(true);
    } else {
      setIsRefreshing(false);
    }

    if (managementQuery.data?.success) {
      const data = managementQuery.data.payload;
      setPageNum(data.chats.page);
      setPageSize(data.chats.pageSize);
      setTotal(data.chats.total);
      setPageNums(getPaginationPages(data.chats.page, data.chats.pageSize, data.chats.total));
    }
  });

  onMount(() => {
    setTitle("批量管理");
    setPage("management");
  });

  const PageButton = (props: { children: JSX.Element; current?: boolean; num: number; maxNum?: number }) => {
    const isInvalid = () => {
      return props.num < 1 || props.num > (props.maxNum || Infinity);
    };

    const handleClick = (e: MouseEvent) => {
      if (isInvalid()) {
        e.preventDefault();
        return;
      }
    };

    const href = () => {
      if (searchParams.keywords) {
        return `?page=${props.num}&keywords=${searchParams.keywords}`;
      } else {
        return `?page=${props.num}`;
      }
    };

    return (
      <a
        href={href()}
        onClick={handleClick}
        class={classNames([
          "px-4 py-2 bg-white card-edge cursor-pointer select-none",
          {
            "bg-blue-600! text-zinc-50": props.current,
            "cursor-not-allowed! opacity-50": isInvalid(),
          },
        ])}
      >
        {props.children}
      </a>
    );
  };

  return (
    <PageBase>
      <div class="w-9/12 my-[1rem] mx-auto flex items-center bg-white/40 border border-line shadow hover:shadow-strong-light rounded-full hover:translate-y-[-2px] transition-all">
        <Icon icon="fluent-color:search-sparkle-16" class="w-[4rem] text-[2rem] text-zinc-400" />
        <input
          placeholder="输入群标题、群描述中的关键字"
          type="text"
          class="flex-1 h-[3.25rem] outline-0 tracking-wider"
          value={editingKeywords()}
          onInput={handleKeywordsInput}
          onKeyDown={handleKeywordsKeyDown}
        />
      </div>
      {/* 数据位置/总数和刷新按钮 */}
      <div class="my-[1rem] p-[1rem] bg-blue-100/40 text-gray-600 rounded-xl flex justify-between items-center card-edge border-l-4! border-l-blue-400!">
        <p>
          显示第 {(pageNum() - 1) * pageSize() + 1} - {pageNum() * pageSize()} 条记录，共 {total()} 条
          <Show when={searchParams.keywords}>
            （“<span class="bg-zinc-50 rounded-lg px-2">{searchParams.keywords}</span>” 的搜索结果）
          </Show>
        </p>
        <div>
          <ActionButton onClick={handleRefresh} loading={isRefreshing()} icon="material-symbols:refresh" outline>
            刷新
          </ActionButton>
        </div>
      </div>
      <table class="w-full outline outline-zinc-100 shadow rounded overflow-hidden">
        <thead class="tracking-wide">
          <tr class="*:px-[1rem] *:py-[1rem] *:bg-gray-100 *:border-zinc-300/70 *:text-left *:text-gray-700">
            <th class="w-4/12 border-r-1">群详情</th>
            <th class="w-3/12 border-r-1">群链接</th>
            <th class="w-3/12 border-r-1 text-center!">加入时间</th>
            <th class="w-2/12 text-right!">操作</th>
          </tr>
        </thead>
        <tbody class="bg-blue-500 *:bg-white *:not-last:border-b *:border-gray-200">
          <For each={managementQuery.data?.success && managementQuery.data.payload.chats.items || []}>
            {(chat) => (
              <tr
                class={classNames([
                  "*:px-[1rem] *:py-[0.5rem] *:text-left *:text-gray-700 hover:bg-blue-50 hover:translate-x-1 transition-all",
                  { "*:text-zinc-400!": chat.left },
                ])}
              >
                <td>
                  <p class="font-medium tracking-wide line-clamp-1">
                    {chat.title}
                  </p>
                  <p class="mt-1 text-sm tracking-wider line-clamp-1">
                    {chat.description || "无描述"}
                  </p>
                </td>
                <td>
                  <ChatLink username={chat.username} />
                </td>
                <td class="text-center!">
                  <span class="text-gray-600 bg-zinc-50 px-2 py-1 rounded-lg">
                    {format(chat.createdAt, "yyyy-MM-dd HH:mm:ss")}
                  </span>
                </td>
                <td class="text-right!">
                  <div class="flex gap-[0.5rem] justify-end">
                    <ActionButton
                      onClick={() => handleSyncChat(chat)}
                      disabled={syncingChats().includes(chat.id)}
                      size="sm"
                      variant="info"
                      outline
                    >
                      同步
                    </ActionButton>
                    <ActionButton
                      onClick={() => handleLeaveChat(chat)}
                      disabled={leavingChats().includes(chat.id)}
                      size="sm"
                      variant="danger"
                      outline
                    >
                      退出
                    </ActionButton>
                  </div>
                </td>
              </tr>
            )}
          </For>
        </tbody>
      </table>
      <div class="mt-[2rem] flex justify-between gap-[0.5rem]">
        <PageButton num={pageNum() - 1}>
          上一页
        </PageButton>
        <div class="flex gap-[0.5rem]">
          <For each={pageNums()}>
            {(num) => (
              <PageButton current={num === pageNum()} num={num}>
                {num}
              </PageButton>
            )}
          </For>
        </div>
        <PageButton num={pageNum() + 1} maxNum={total() ? Math.ceil(total() / pageSize()) : undefined}>
          下一页
        </PageButton>
      </div>
    </PageBase>
  );
};
