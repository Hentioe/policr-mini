import { createEffect, createSignal } from "solid-js";

export default (props: { label: string; default?: boolean; onChange?: (checked: boolean) => void }) => {
  const [checked, setChecked] = createSignal<boolean | undefined>(undefined);
  const toggleChecked = () => {
    const newState = !checked();
    setChecked(newState);
    props.onChange?.(newState);
  };

  createEffect(() => {
    if (checked() === undefined && props.default) {
      setChecked(props.default);
    }
  });

  return (
    <div class="flex items-center gap-[0.5rem] select-none cursor-pointer" onClick={toggleChecked}>
      <span>{props.label}</span>
      <input
        type="checkbox"
        checked={checked()}
        class="w-[1rem] h-[1rem] outline-0 border border-zinc-200 shadow rounded"
      />
    </div>
  );
};
