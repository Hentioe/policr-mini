export { default as WindowDetector } from "./window-detector";

import { createToaster } from "@ark-ui/solid";

export const toaster = createToaster({
  placement: "bottom-end",
  overlap: true,
  gap: 24,
});
