import { Checkbox, CheckboxCheckedChangeDetails } from "@ark-ui/solid/checkbox";
import { Icon } from "@iconify-icon/solid";

export default (props: { label: string; checked?: boolean; onChange?: (checked: boolean) => void }) => {
  const handleChange = (details: CheckboxCheckedChangeDetails) => {
    props.onChange?.(details.checked as boolean);
  };

  return (
    <Checkbox.Root checked={props.checked} onCheckedChange={handleChange}>
      <Checkbox.Label>{props.label}</Checkbox.Label>
      <Checkbox.Control>
        <Checkbox.Indicator>
          <Icon icon="material-symbols:check-box-sharp" />
        </Checkbox.Indicator>
      </Checkbox.Control>
      <Checkbox.HiddenInput />
    </Checkbox.Root>
  );
};
