import { useQuery } from "@tanstack/solid-query";
import { format } from "date-fns";
import { createEffect, createSignal, For, Match, Show, Switch } from "solid-js";
import { getVerifications } from "../../api";
import { ActionButton } from "../../components";
import { Record } from "./Record";

type Verification = ServerData.Verification;

export default (props: { chatId: number | null; range: string }) => {
  const [maxReached, setMaxReached] = createSignal(false);
  const query = useQuery(() => ({
    queryKey: ["verifications", props.chatId, props.range],
    queryFn: () => getVerifications(props.chatId!, props.range),
    enabled: props.chatId != null,
  }));

  createEffect(() => {
    if (query.data?.success && query.data.payload.length >= 120) {
      setMaxReached(true);
    } else {
      setMaxReached(false);
    }
  });

  const BanOrUnbanButton = (props: { v: Verification }) => {
    const isBanned = () => {
      switch (props.v.status) {
        case "approved":
        case "pending":
          return false;
        case "incorrect":
        case "timeout":
        case "expired":
        case "manual_kick":
        case "manual_ban":
          return true;
      }
    };

    return (
      <Switch>
        <Match when={isBanned()}>
          <ActionButton icon="fluent:lock-open-24-regular" variant="success" size="sm" outline>解禁</ActionButton>
        </Match>
        <Match when={true}>
          <ActionButton icon="mdi:ban" variant="danger" size="sm" outline>封禁</ActionButton>
        </Match>
      </Switch>
    );
  };

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const ReVerificationButton = (_props: { v: Verification }) => {
    return <ActionButton icon="uis:redo" variant="info" size="sm" outline>重新验证</ActionButton>;
  };

  return (
    <div>
      <Show when={query.data?.success}>
        <For each={query.data?.success && query.data.payload}>
          {(v) => (
            <Record.Root
              user={v.userFullName}
              badge={renderBadge(v)}
              bottoms={[<BanOrUnbanButton v={v} />, <ReVerificationButton v={v} />]}
            >
              <Record.Details>
                <Record.Detail
                  text={format(v.insertedAt, "yyyy-MM-dd HH:mm:ss")}
                  icon="material-symbols:date-range-outline-sharp"
                />
                <Record.Detail text={`${v.durationSecs}s`} icon="mingcute:time-duration-line" />
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

function renderBadge(v: ServerData.Verification) {
  const badgeType = () => {
    switch (v.status) {
      case "pending":
        return "info";
      case "approved":
        return "success";
      case "incorrect":
        return "error";
      case "timeout":
        return "warning";
      case "expired":
        return "error";
      case "manual_kick":
        return "warning";
      case "manual_ban":
        return "error";
    }
  };

  const badgeText = () => {
    switch (v.status) {
      case "pending":
        return "等待中";
      case "approved":
        return "通过";
      case "incorrect":
        return "错误";
      case "timeout":
        return "超时";
      case "expired":
        return "过期";
      case "manual_kick":
        return "手动踢出";
      case "manual_ban":
        return "手动封禁";
    }
  };

  return <Record.Badge type={badgeType()} text={badgeText()} />;
}
