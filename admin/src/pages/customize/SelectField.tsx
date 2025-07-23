import { SingleSelect } from "../../components";
import FieldRoot from "./FieldRoot";

export default (
  props: {
    label: string;
    placeholder: string;
    items: SelectItem[];
    default?: string;
    onChange?: (item: SelectItem) => void;
  },
) => {
  return (
    <FieldRoot label={props.label}>
      <SingleSelect
        placeholder={props.placeholder}
        items={props.items}
        onChange={props.onChange}
        default={props.default}
      />
    </FieldRoot>
  );
};
