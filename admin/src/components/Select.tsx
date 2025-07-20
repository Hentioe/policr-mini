import { createListCollection, Select } from "@ark-ui/solid/select";
import { Icon } from "@iconify-icon/solid";
import { createEffect, createMemo, createSignal, Index } from "solid-js";
import { Portal } from "solid-js/web";

export default (
  props: {
    placeholder?: string;
    open?: boolean;
    onChange?: (item: SelectItem) => void;
    items: SelectItem[];
    default?: string;
  },
) => {
  const [value, setValue] = createSignal<string[]>([]);
  const collection = createMemo(() => createListCollection<SelectItem>({ items: props.items }));

  createEffect(() => {
    if (value().length === 0 && props.default) {
      setValue([props.default]);
    }
  });

  const handleChange = (item: SelectItem) => {
    setValue([item.value]);
    props.onChange?.(item);
  };

  return (
    <Select.Root
      value={value()}
      collection={collection()}
      onValueChange={(e) => handleChange(e.items[0])}
      open={props.open}
    >
      <Select.Control>
        <Select.Trigger>
          <Select.ValueText placeholder={props.placeholder} />
          <Select.Indicator>
            <Icon icon="lucide:chevrons-up-down" class="text-zinc-300 w-[1rem]" />
          </Select.Indicator>
        </Select.Trigger>
      </Select.Control>
      <Portal>
        <Select.Positioner>
          <Select.Content>
            <Select.ItemGroup>
              <Index each={collection().items}>
                {(item) => (
                  <Select.Item item={item()}>
                    <Select.ItemText>{item().label}</Select.ItemText>
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
