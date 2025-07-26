import { destructure } from "@solid-primitives/destructure";
import { createSignal, onMount } from "solid-js";
import { Range } from "../../components/Range";
import { PageBase } from "../../layouts";
import { globalState } from "../../state";
import { setCurrentPage } from "../../state/global";
import { setTitle } from "../../state/meta";
import Operations from "./Operations";
import { Pages } from "./Pages";
import Verifications from "./Verifications";

const RANGE_ITEMS = [
  { value: "today", label: "今天" },
  { value: "7d", label: "最近 7 天" },
  { value: "30d", label: "最近 30 天" },
];

export default () => {
  const { currentChatId } = destructure(globalState);
  const [range, setRange] = createSignal(RANGE_ITEMS[1].value);

  const handleRangeChange = (value: string) => {
    setRange(value);
  };

  onMount(() => {
    setCurrentPage("histories");
    setTitle("历史");
  });

  return (
    <PageBase>
      <div class="mb-[0.5rem]">
        <Range.List items={RANGE_ITEMS}>
          {(item) => (
            <Range.Item
              value={item.value}
              label={item.label}
              active={range() == item.value}
              onClick={handleRangeChange}
            />
          )}
        </Range.List>
      </div>
      <Pages.Root defaultPage="验证记录">
        <Pages.Head list={["验证记录", "操作记录"]} />
        <Pages.Content title="验证记录">
          <Verifications chatId={currentChatId()} range={range()} />
        </Pages.Content>
        <Pages.Content title="操作记录">
          <Operations chatId={currentChatId()} range={range()} />
        </Pages.Content>
      </Pages.Root>
    </PageBase>
  );
};
