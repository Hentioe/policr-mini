import { destructure } from "@solid-primitives/destructure";
import { JSX, Match, Switch } from "solid-js";
import { globalState } from "../state";

export default (props: { children: JSX.Element }) => {
  const { emptyChatList } = destructure(globalState);

  return (
    <main class="pt-main-top pb-main-bottom min-h-screen bg-white px-edge text-foreground overflow-y-auto">
      <Switch>
        <Match when={emptyChatList() === true}>
          <p class="text-center text-gray-500 tracking-wider">您不是任何群组的管理员</p>
        </Match>
        <Match when={true}>
          {props.children}
        </Match>
      </Switch>
    </main>
  );
};
