import { useQuery } from "@tanstack/solid-query";
import { format } from "date-fns";
import { createEffect, createSignal, For, Match, Show, Switch } from "solid-js";
import { getOperations } from "../../api";
import Loading from "../../components/Loading";
import { toaster } from "../../utils";
import { Record } from "./Record";

type Operation = ServerData.Operation;

export default (props: { chatId: number | null; range: string }) => {
  const [maxReached, setMaxReached] = createSignal(false);
  const [isEmpty, setIsEmpty] = createSignal(false);
  const query = useQuery(() => ({
    queryKey: ["operations", props.chatId, props.range],
    queryFn: () => getOperations(props.chatId!, props.range),
    enabled: props.chatId != null,
  }));

  createEffect(() => {
    if (!query.data) {
      return;
    }
    if (query.data.success === false) {
      toaster.error({ title: "操作记录加载失败", description: query.data?.message });
      return;
    }
    if (query.data.payload.length === 0) {
      setIsEmpty(true);
    } else if (query.data.payload.length >= 120) {
      setMaxReached(true);
    } else {
      setMaxReached(false);
    }
  });

  return (
    <div>
      <Switch>
        <Match when={query.isLoading}>
          <MyLoading />
        </Match>
        <Match when={isEmpty()}>
          <Empty />
        </Match>
        <Match when={true}>
          <For each={query.data?.success && query.data.payload}>
            {(ope) => (
              <Record.Root
                user={ope.verification.userFullName}
                badge={renderActionBadge(ope)}
                bottoms={[renderRoleBadge(ope)]}
              >
                <Record.Details>
                  <Record.Detail
                    text={format(ope.insertedAt, "yyyy-MM-dd HH:mm:ss")}
                    icon="material-symbols:date-range-outline-sharp"
                  />
                </Record.Details>
              </Record.Root>
            )}
          </For>
          <Show when={maxReached()}>
            <p class="mt-[1rem] text-center text-gray-500 tracking-wide">已达到最大展示数量限制</p>
          </Show>
        </Match>
      </Switch>
    </div>
  );
};

function renderActionBadge(ope: Operation) {
  const badgeType = () => {
    switch (ope.action) {
      case "kick":
        return "warning";
      case "ban":
        return "error";
      case "unban":
        return "success";
      case "verify":
        return "warning";
    }
  };

  const badgeText = () => {
    switch (ope.action) {
      case "kick":
        return "踢出";
      case "ban":
        return "封禁";
      case "unban":
        return "解禁";
      case "verify":
        return "重新验证";
    }
  };

  return <Record.Badge type={badgeType()} text={badgeText()} />;
}

function renderRoleBadge(ope: Operation) {
  const badgeType = () => {
    switch (ope.role) {
      case "system":
        return "success";
      case "admin":
        return "info";
    }
  };

  const badgeText = () => {
    switch (ope.role) {
      case "system":
        return "系统";
      case "admin":
        return "管理员";
    }
  };

  return <Record.Badge type={badgeType()} text={badgeText()} />;
}

const MyLoading = () => {
  return (
    <div class="flex items-center justify-center mt-[2rem]">
      <Loading size="xl" color="skyblue" />
    </div>
  );
};

const Empty = () => {
  return (
    <div class="mt-[2rem]">
      <p class="text-center text-zinc-600 tracking-wide">没有找到相关的操作记录</p>
    </div>
  );
};
