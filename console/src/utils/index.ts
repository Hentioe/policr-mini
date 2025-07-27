import { createToaster } from "@ark-ui/solid";

export const toaster = createToaster({
  placement: "top",
  duration: 1500,
  overlap: true,
  gap: 24,
});
