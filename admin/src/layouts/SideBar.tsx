import { Icon, IconifyIcon } from "@iconify-icon/solid";
import { destructure } from "@solid-primitives/destructure";
import classNames from "classnames";
import { globalState } from "../state";

export default () => {
  const { page } = destructure(globalState);

  return (
    <nav class="pt-title-bar-height bg-white/20 w-[8rem] h-full mr-[1rem] border-r border-line">
      <div class="flex flex-col">
        <NavLink href="/admin/v2" text="仪表盘" icon="ant-design:dashboard-outlined" active={page() === "dashboard"} />
        <NavLink
          href="/admin/v2/customize"
          text="全局调整"
          icon="hugeicons:customize"
          active={page() === "customize"}
        />
        <NavLink href="/admin/v2/management" text="批量管理" icon="mdi:users-group" active={page() === "management"} />
        <NavLink href="/admin/v2/assets" text="验证资源" icon="grommet-icons:resources" active={page() === "assets"} />
        <NavLink href="/admin/v2/tasks" text="系统任务" icon="fa-solid:tasks" active={page() === "tasks"} />
        <NavLink href="/admin/v2/terms" text="服务条款" icon="solar:document-broken" active={page() === "terms"} />
      </div>
    </nav>
  );
};

const NavLink = (props: { href: string; text: string; icon: string | IconifyIcon; active?: boolean }) => {
  return (
    <a
      class={classNames([
        "py-[0.25rem] px-[0.5rem] h-[5rem] text-zinc-600 hover:bg-blue-300 hover:text-zinc-100 hover:translate-x-[0.25rem] hover:shadow transition-all flex flex-col justify-center",
        { "bg-blue-400! text-zinc-100!": props.active },
      ])}
      href={props.href}
    >
      <Icon icon={props.icon} inline class="h-[2rem] text-3xl" />
      <span class="mt-2 text-center">{props.text}</span>
    </a>
  );
};
