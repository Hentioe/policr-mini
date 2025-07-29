import { useQuery } from "@tanstack/solid-query";
import { format } from "date-fns";
import { createEffect, createSignal, For, Match, Show, Switch } from "solid-js";
import { createStore } from "solid-js/store";
import { getVerifications, killFromVerification } from "../../api";
import { ActionButton } from "../../components";
import Loading from "../../components/Loading";
import { toaster } from "../../utils";
import { Record } from "./Record";

type Verification = ServerData.Verification;

export default (props: { chatId: number | null; range: string }) => {
  const [maxReached, setMaxReached] = createSignal(false);
  const [isEmpty, setIsEmpty] = createSignal(false);
  const [executing, setExecuting] = createStore<{ killing: number[]; banning: number[]; unbanning: number[] }>({
    killing: [],
    banning: [],
    unbanning: [],
  });
  const query = useQuery(() => ({
    queryKey: ["verifications", props.chatId, props.range],
    queryFn: () => getVerifications(props.chatId!, props.range),
    enabled: props.chatId != null,
  }));

  const handleKill = async (id: number, action: InputData.VerificationKillAction) => {
    let actionText;
    switch (action) {
      case "manual_ban":
        actionText = "封禁";
        setExecuting("banning", prev => [...prev, id]);
        break;
      case "manual_kick":
        actionText = "踢出";
        setExecuting("killing", prev => [...prev, id]);
        break;
      case "unban":
        actionText = "解禁";
        setExecuting("unbanning", prev => [...prev, id]);
        break;
    }
    const resp = await killFromVerification(id, action);
    setExecuting("killing", prev => prev.filter(i => i !== id));
    setExecuting("banning", prev => prev.filter(i => i !== id));
    setExecuting("unbanning", prev => prev.filter(i => i !== id));
    if (resp.success) {
      toaster.success({ title: "操作成功", description: `已${actionText}用户` });
    } else {
      toaster.error({ title: "操作失败", description: resp.message });
    }
  };

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const handleReVerification = async (_id: number) => {
    toaster.error({ title: "功能尚未实现", description: "请关注后续更新。" });
  };

  createEffect(() => {
    if (!query.data) {
      return;
    }
    if (query.data.success === false) {
      toaster.error({ title: "验证记录加载失败", description: query.data?.message });
      return;
    }
    if (query.data.payload.length === 0) {
      setIsEmpty(true);
    } else if (query.data.payload.length >= 120) {
      setIsEmpty(false);
      setMaxReached(true);
    } else {
      setIsEmpty(false);
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
          <ActionButton
            onClick={() => handleKill(props.v.id, "unban")}
            loading={executing.unbanning.includes(props.v.id)}
            icon="fluent:lock-open-24-regular"
            variant="success"
            size="sm"
            outline
          >
            解禁
          </ActionButton>
        </Match>
        <Match when={true}>
          <ActionButton
            onClick={() => handleKill(props.v.id, "manual_ban")}
            loading={executing.banning.includes(props.v.id)}
            icon="mdi:ban"
            variant="danger"
            size="sm"
            outline
          >
            封禁
          </ActionButton>
          <ActionButton
            onClick={() => handleKill(props.v.id, "manual_kick")}
            loading={executing.killing.includes(props.v.id)}
            icon="cuida:user-remove-outline"
            variant="warning"
            size="sm"
            outline
          >
            踢出
          </ActionButton>
        </Match>
      </Switch>
    );
  };

  const ReVerificationButton = (props: { v: Verification }) => {
    return (
      <ActionButton onClick={() => handleReVerification(props.v.id)} icon="uis:redo" variant="info" size="sm" outline>
        重新验证
      </ActionButton>
    );
  };

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
            {(v) => (
              <Record.Root
                user={v.userFullName}
                badge={renderBadge(v)}
                bottoms={[<ReVerificationButton v={v} />, <BanOrUnbanButton v={v} />]}
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
        </Match>
      </Switch>
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
      <p class="text-center text-zinc-600 tracking-wide">没有找到相关的验证记录</p>
    </div>
  );
};
