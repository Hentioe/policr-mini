import { Icon, IconifyIcon } from "@iconify-icon/solid";
import classNames from "classnames";

export default () => (
  <nav class="bg-zinc-100 w-[8rem] mr-[1rem] rounded-[2rem] py-[2rem] shadow border border-zinc-200">
    <div class="flex flex-col">
      <NavLink href="/admin/v2" text="仪表盘" icon="ant-design:dashboard-outlined" active />
      <NavLink href="/admin/v2/customize" text="全局调整" icon="hugeicons:customize" />
      <NavLink href="/admin/v2/management" text="批量管理" icon="mdi:users-group" />
      <NavLink href="/admin/v2/assets" text="验证资源" icon="grommet-icons:resources" />
      <NavLink href="/admin/v2/tasks" text="系统任务" icon="fa-solid:tasks" />
      <NavLink href="/admin/v2/terms" text="服务条款" icon="solar:document-broken" />
    </div>
  </nav>
);

const NavLink = (props: { href: string; text: string; icon: string | IconifyIcon; active?: boolean }) => {
  return (
    <a
      class={classNames([
        "py-[0.25rem] px-[0.5rem] h-[5rem] text-zinc-600 hover:bg-blue-300 hover:text-zinc-200 transition-colors flex flex-col justify-center",
        { "bg-blue-400! text-zinc-100!": props.active },
      ])}
      href={props.href}
    >
      <Icon icon={props.icon} inline class="h-[2rem] text-3xl" />
      <span class="mt-2 text-center">{props.text}</span>
    </a>
  );
};
