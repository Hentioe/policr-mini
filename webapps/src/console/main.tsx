import { render } from "solid-js/web";
import GlobalStyles from "./styles/GlobalStyles";
import "./main.scss";
import App from "./App";

render(
  () => (
    <>
      <GlobalStyles />
      <App />
    </>
  ),
  document.getElementById("app")!,
);
