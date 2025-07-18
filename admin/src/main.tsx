import { render } from "solid-js/web";
import "./main.css";
import { QueryClient, QueryClientProvider } from "@tanstack/solid-query";
import App from "./App";
const client = new QueryClient();

render(
  () => (
    <QueryClientProvider client={client}>
      <App />
    </QueryClientProvider>
  ),
  document.getElementById("app")!,
);
