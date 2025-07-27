import { Dialog } from "@ark-ui/solid/dialog";
import { Icon } from "@iconify-icon/solid";
import { JSX } from "solid-js";
import { Portal } from "solid-js/web";

export default (props: { open: boolean; title: string; children: JSX.Element; onClose?: () => void }) => {
  return (
    <>
      <Dialog.Root open={props.open}>
        <Portal>
          <Dialog.Backdrop />
          <Dialog.Positioner>
            <Dialog.Content>
              <Dialog.Title>{props.title}</Dialog.Title>
              {props.children}
              <Dialog.CloseTrigger onClick={props.onClose}>
                <Icon icon="mingcute:close-line" />
              </Dialog.CloseTrigger>
            </Dialog.Content>
          </Dialog.Positioner>
        </Portal>
      </Dialog.Root>
    </>
  );
};
