import { destructure } from "@solid-primitives/destructure";
import { useQuery } from "@tanstack/solid-query";
import { onMount } from "solid-js";
import { getCustoms } from "../../api";
import { ActionButton } from "../../components";
import { PageBase } from "../../layouts";
import { globalState } from "../../state";
import { setCurrentPage } from "../../state/global";
import { setTitle } from "../../state/meta";
import { Adding } from "./Adding";
import List from "./List";

export default () => {
  const { currentChatId } = destructure(globalState);

  const query = useQuery(() => ({
    queryKey: ["customs"],
    queryFn: () => getCustoms(currentChatId()!),
    enabled: !!currentChatId(),
  }));

  onMount(() => {
    setCurrentPage("customize");
    setTitle("自定义");
  });

  return (
    <PageBase>
      <div class="bg-white">
        <h2 class="text-center font-bold">已添加的自定义验证</h2>
        <List.Root items={query.data?.success && query.data.payload || []}>
          {(item) => <List.Item item={item} />}
        </List.Root>
      </div>
      <div class="mt-[1rem] pb-button-lg">
        <Adding.Root>
          <Adding.Field label="标题">
            <Adding.Input placeholder="输入问题标题" />
          </Adding.Field>
          <Adding.Field label="附件">
            <Adding.Input placeholder="私聊机器人任意文件获取此值" />
          </Adding.Field>
          <Adding.Answer label="答案1" correct />
          <Adding.Answer label="答案2" />
          <Adding.Answer label="答案3" />
        </Adding.Root>
        <div class="mt-[1rem]">
          <ActionButton size="lg" fullWidth outline>
            继续增加答案
          </ActionButton>
        </div>
        <div class="fixed bottom-navigation left-0 right-0 px-edge flex gap-[1rem]">
          <ActionButton variant="info" size="lg" icon="mdi:eye" fullWidth outline>
            预览
          </ActionButton>
          <ActionButton variant="info" size="lg" icon="material-symbols:save" fullWidth>
            保存
          </ActionButton>
        </div>
      </div>
    </PageBase>
  );
};
