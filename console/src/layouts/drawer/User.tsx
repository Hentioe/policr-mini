import { Show } from "solid-js";

{/* todo: 颜色不断运动的彩色背景 */}

export default (props: { user?: ServerData.User }) => {
  return (
    <div class="p-[1rem] h-[12.5rem] bg-white/40 backdrop-blur-md">
      <Show when={props.user} fallback={<Loading />}>
        <div class="w-full py-[1rem] bg-zinc-300 rounded-xl shadow flex flex-col items-center gap-[0.5rem]">
          <img
            width={320}
            height={320}
            src="/console/v2/user_photo"
            alt="用户头像"
            class="w-[7rem] h-[7rem] rounded-full shadow"
          />
          <p class="h-[1rem] text-gray-600 text-center">
            你好，{props.user?.fullName}
          </p>
        </div>
      </Show>
    </div>
  );
};

const Loading = () => {
  return (
    <div class="h-full flex justify-center items-center">
      <p>加载中……</p>
    </div>
  );
};
