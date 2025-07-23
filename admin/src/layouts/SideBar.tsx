import { Icon, IconifyIcon } from "@iconify-icon/solid";
import { destructure } from "@solid-primitives/destructure";
import { useQuery } from "@tanstack/solid-query";
import classNames from "classnames";
import { Match, Switch } from "solid-js";
import { getServerInfo } from "../api";
import { globalState } from "../state";

export default () => {
  const { page } = destructure(globalState);
  const query = useQuery(() => ({
    queryKey: ["server-info"],
    queryFn: getServerInfo,
  }));

  return (
    <nav class="pt-title-bar-height bg-white/20 w-[8rem] h-full mr-[1rem] border-r border-line">
      <div class="h-full flex flex-col justify-between">
        <div>
          <NavLink
            href="/admin/v2"
            text="仪表盘"
            icon="ant-design:dashboard-outlined"
            active={page() === "dashboard"}
          />
          <NavLink
            href="/admin/v2/customize"
            text="全局调整"
            icon="hugeicons:customize"
            active={page() === "customize"}
          />
          <NavLink
            href="/admin/v2/management"
            text="批量管理"
            icon="mdi:users-group"
            active={page() === "management"}
          />
          <NavLink
            href="/admin/v2/assets"
            text="验证资源"
            icon="grommet-icons:resources"
            active={page() === "assets"}
          />
          <NavLink href="/admin/v2/tasks" text="系统任务" icon="fa-solid:tasks" active={page() === "tasks"} />
          <NavLink href="/admin/v2/terms" text="服务条款" icon="solar:document-broken" active={page() === "terms"} />
        </div>
        <div>
          <ExternalLink icon="entypo:new" text="有新需求" href="https://blog.gramlabs.org/contact.html" />
          <InfoView title="VERSION" text={query.data?.success ? query.data.payload.server.version : "..."} />
          <InfoView title="CAPINDE" text={query.data?.success ? `v${query.data.payload.capinde.version}` : "..."} />
        </div>
      </div>
    </nav>
  );
};

const NavLink = (props: { href: string; text: string; icon: string | IconifyIcon; active?: boolean }) => {
  return (
    <a
      class={classNames([
        "py-[0.25rem] px-[0.5rem] h-[5rem] text-zinc-600 select-none hover:bg-blue-300 hover:text-zinc-100 hover:translate-x-[0.25rem] hover:shadow transition-all flex flex-col justify-center",
        { "bg-blue-400! text-zinc-100!": props.active },
      ])}
      href={props.href}
    >
      <Icon icon={props.icon} inline class="h-[2rem] text-3xl" />
      <span class="mt-2 text-center">{props.text}</span>
    </a>
  );
};

const ExternalLink = (props: { text: string; icon: string | IconifyIcon; href: string }) => {
  return (
    <a
      href={props.href}
      target="_blank"
      class={classNames([
        "py-[0.25rem] px-[0.5rem] h-[5rem] text-blue-400 hover:text-zinc-100 hover:bg-blue-400 select-none flex flex-col justify-center items-center ",
      ])}
    >
      <Icon icon={props.icon} inline class="h-[2rem] text-3xl" />
      <span class="mt-2 text-sm font-bold tracking-wide">{props.text}</span>
    </a>
  );
};

const InfoView = (props: { text: string; title?: string; icon?: string | IconifyIcon }) => {
  return (
    <div
      class={classNames([
        "py-[0.25rem] px-[0.5rem] h-[5rem] text-zinc-600 select-none flex flex-col justify-center items-center",
      ])}
    >
      <Switch>
        <Match when={props.title}>
          <span class="text-[0.9rem] text-zinc-500 font-medium tracking-widest">{props.title}</span>
        </Match>
        <Match when={props.icon}>
          <Icon icon={props.icon!} inline class="h-[2rem] text-3xl" />
        </Match>
      </Switch>
      <span class="mt-2 text-xs text-zinc-400 tracking-wide">{props.text}</span>
    </div>
  );
};
