import { render } from "solid-js/web";
import "./main.css";
import { QueryClient, QueryClientProvider } from "@tanstack/solid-query";
import App from "./App";

const client = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false, // 禁止在窗口重新聚焦时重新获取数据
    },
  },
});

render(
  () => (
    <QueryClientProvider client={client}>
      <App />
    </QueryClientProvider>
  ),
  document.getElementById("app")!,
);
