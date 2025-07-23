import { Dialog } from "@ark-ui/solid/dialog";
import { Portal } from "solid-js/web";

export default (props: { open: boolean }) => {
  return (
    <Dialog.Root open={props.open}>
      <Portal>
        <Dialog.Backdrop />
        <Dialog.Positioner>
          <Dialog.Content>
            <Dialog.Title>窗口宽度不足</Dialog.Title>
            <Dialog.Description>
              请将浏览器窗口调整到更大的尺寸，如果您用的手机浏览器请切换到桌面模式。
            </Dialog.Description>
          </Dialog.Content>
        </Dialog.Positioner>
      </Portal>
    </Dialog.Root>
  );
};
