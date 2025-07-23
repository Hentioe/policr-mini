import { Icon, IconifyIcon } from "@iconify-icon/solid";
import { format } from "date-fns";
import { JSX } from "solid-js";


const Root = (props: { title: string; icon: string | IconifyIcon; children: JSX.Element }) => {
  return (
    <div class="w-[26rem] bg-card card-edge flex flex-col">
      <h3 class="text-xl font-bold text-center py-[1rem] border-b border-line">
        {props.title}
        <Icon inline icon={props.icon} class="w-[1.25rem] ml-[0.5rem]" />
      </h3>
      {props.children}
    </div>
  );
};


const Field = (props: { name: string; value: string | number }) => {
  return (
    <div class="py-[1rem] hover:bg-zinc-200/40">
      <p class="text-center text-lg font-medium">{props.name}</p>
      <p class="text-center mt-[0.25rem] text-zinc-500 tracking-wide">{props.value}</p>
    </div>
  );
};

const Fields = (props: { manifest: ServerData.Manifest; imagesCount: number }) => {
  return (
    <>
      <Field name="制作日期" value={format(props.manifest.datetime, "yyyy-MM-dd HH:mm:ss")} />
      <Field name="版本" value={props.manifest.version} />
      <Field name="图集数量" value={props.manifest.albums.length} />
      <Field name="图片总数" value={props.imagesCount} />
    </>
  );
};

const ActionList = (props: { children: JSX.Element }) => {
  return (
    <div class="flex justify-center gap-[1rem] p-[1rem] border-t border-zinc-300/80">
      {props.children}
    </div>
  );
};


export const Manifest = {
  Root,
  ActionList,
  Fields,
  Field
}