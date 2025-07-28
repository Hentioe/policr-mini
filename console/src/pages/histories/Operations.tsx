import { useQuery } from "@tanstack/solid-query";
import { format } from "date-fns";
import { createEffect, createSignal, For, Show } from "solid-js";
import { getOperations } from "../../api";
import { Record } from "./Record";

type Operation = ServerData.Operation;

export default (props: { chatId: number | null; range: string }) => {
  const [maxReached, setMaxReached] = createSignal(false);
  const query = useQuery(() => ({
    queryKey: ["operations", props.chatId, props.range],
    queryFn: () => getOperations(props.chatId!, props.range),
    enabled: props.chatId != null,
  }));

  createEffect(() => {
    if (query.data?.success && query.data.payload.length >= 120) {
      setMaxReached(true);
    } else {
      setMaxReached(false);
    }
  });

  return (
    <div>
      <Show when={query.data?.success}>
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
      </Show>
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
