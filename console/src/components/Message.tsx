import classnames from "classnames";
import { For, JSX, Match, Show, Switch } from "solid-js";

type Button = {
  text: string;
  type?: "url" | "button";
};

export default (props: { children?: JSX.Element; photo?: string; keyboard?: Button[][] }) => {
  return (
    <div class="flex">
      <a href="https://t.me/policr_mini_bot" target="_blank" class="w-[5rem] self-end mr-[1rem] ">
        <img
          src="/own_photo"
          width={160}
          height={160}
          class="rounded-full shadow"
        />
      </a>
      <div class="flex-1">
        <div class="shadow rounded-xl overflow-hidden">
          <Switch>
            <Match when={!props.photo}>
              <p class="mb-[0.5rem] px-[1rem] pt-[1rem] font-bold text-amber-500">Policr Mini (beta)</p>
            </Match>
            <Match when={true}>
              {props.photo && <img src={props.photo} height={360} width={540} class="w-full mb-[1rem]" />}
            </Match>
          </Switch>
          <Show when={props.children}>
            <div class="px-[1rem] pb-[1rem]">
              {props.children}
            </div>
          </Show>
        </div>
        <Show when={props.keyboard && props.keyboard.length > 0}>
          <div
            class={classnames(["mt-[0.5rem] grid gap-1 rounded-lg overflow-hidden", {
              "grid-cols-1": props.keyboard?.length === 1,
              "grid-cols-3": props.keyboard?.length === 3,
            }])}
          >
            <For each={props.keyboard}>
              {(row) => (
                <For each={row}>
                  {(button) => (
                    <button
                      class={classnames(["bg-blue-500/60 text-white/80 rounded cursor-pointer py-2 px-4", {
                        "underline": button.type === "url",
                      }])}
                    >
                      {button.text}
                    </button>
                  )}
                </For>
              )}
            </For>
          </div>
        </Show>
      </div>
    </div>
  );
};
