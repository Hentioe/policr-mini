import { createListCollection, Select } from "@ark-ui/solid/select";
import { Icon } from "@iconify-icon/solid";
import { Index } from "solid-js";
import { Portal } from "solid-js/web";

export default (props: { placeholder?: string; open?: boolean }) => {
  const collection = createListCollection({ items: ["React", "Solid", "Vue", "Svelte"] });
  return (
    <Select.Root collection={collection} open={props.open}>
      <Select.Control>
        <Select.Trigger>
          <Select.ValueText placeholder={props.placeholder || "选择一个值"} />
          <Select.Indicator>
            <Icon icon="lucide:chevrons-up-down" class="text-zinc-300 w-[1rem]" />
          </Select.Indicator>
        </Select.Trigger>
      </Select.Control>
      <Portal>
        <Select.Positioner>
          <Select.Content>
            <Select.ItemGroup>
              <Index each={collection.items}>
                {(item) => (
                  <Select.Item item={item()}>
                    <Select.ItemText>{item()}</Select.ItemText>
                    <Select.ItemIndicator>
                      <Icon icon="material-symbols:check" />
                    </Select.ItemIndicator>
                  </Select.Item>
                )}
              </Index>
            </Select.ItemGroup>
          </Select.Content>
        </Select.Positioner>
      </Portal>
      <Select.HiddenSelect />
    </Select.Root>
  );
};
