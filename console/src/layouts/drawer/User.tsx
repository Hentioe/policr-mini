import { Match, Switch } from "solid-js";

{/* todo: 颜色不断运动的彩色背景 */}

export default (props: { user?: ServerData.User | false }) => {
  return (
    <div class="p-[1rem] h-[12.5rem] bg-white/40 backdrop-blur-md">
      <Switch>
        <Match when={props.user}>
          <div class="w-full py-[1rem] bg-zinc-300 rounded-xl shadow flex flex-col items-center gap-[0.5rem]">
            <img
              width={320}
              height={320}
              src="/images/avatar.webp"
              alt="用户头像"
              class="w-[7rem] h-[7rem] rounded-full shadow"
            />
            <p class="h-[1rem] text-gray-600 text-center">
              你好，小红红
            </p>
          </div>
        </Match>
        <Match when={true}>
          <div class="h-full flex justify-center items-center">
            <p>加载中……</p>
          </div>
        </Match>
      </Switch>
    </div>
  );
};
