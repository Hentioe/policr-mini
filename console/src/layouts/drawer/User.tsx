import { Show } from "solid-js";
import Loading from "../../components/Loading";

{/* todo: 颜色不断运动的彩色背景 */}
export default (props: { data?: ServerData.User }) => {
  return (
    <div class="p-[1rem] h-[13rem] bg-white/40 backdrop-blur-md">
      <Show when={props.data} fallback={<MyLoading />}>
        <div class="w-full py-[1rem] user-bg rounded-xl shadow flex flex-col items-center gap-[0.5rem]">
          <img
            width={320}
            height={320}
            src={`/console/v2/${props.data?.id}/photo`}
            alt="用户头像"
            class="w-[7rem] h-[7rem] rounded-full shadow"
          />
          <div class="h-[1.5rem] flex items-center px-[1rem] text-zinc-50 bg-zinc-300/30 rounded-full max-w-user-prompt">
            <p class="text-nowrap line-clamp-1 truncate">
              你好，{props.data?.fullName}
            </p>
          </div>
        </div>
      </Show>
    </div>
  );
};

const MyLoading = () => {
  return (
    <div class="flex items-center justify-center h-full">
      <Loading size="xl" color="lightcoral" />
    </div>
  );
};
