import { Icon, IconifyIcon } from "@iconify-icon/solid";
import { useQuery } from "@tanstack/solid-query";
import classNames from "classnames";
import { format } from "date-fns";
import { JSX, Match, onMount, Switch } from "solid-js";
import { getAssets } from "../api";
import { PageBase } from "../layouts";
import { setPage } from "../state/global";
import { setTitle } from "../state/meta";

type Assets = ServerData.Assets;

export default () => {
  const query = useQuery(() => ({
    queryKey: ["assets"],
    queryFn: getAssets,
  }));

  onMount(() => {
    setTitle("验证资源");
    setPage("assets");
  });

  return (
    <PageBase>
      <div class="flex justify-between">
        <Manifest title="已部署的资源" icon="flat-color-icons:ok">
          <Switch>
            <Match when={query.isLoading}>
              <Loading />
            </Match>
            <Match when={query.data?.success && query.data.payload.deployed}>
              <ManifestFields
                manifest={(query.data?.payload as Assets).deployed!.manifest}
                imagesCount={(query.data?.payload as Assets).deployed!.imagesTotal}
              />
              <ManifestActionList>
                <ManifestAction level="danger">
                  删除
                </ManifestAction>
              </ManifestActionList>
            </Match>
            <Match when={true}>
              <NotFound>
                暂未部署资源
              </NotFound>
            </Match>
          </Switch>
        </Manifest>
        <Manifest title="已上传的资源" icon="emojione-v1:warning">
          <Switch>
            <Match when={query.isLoading}>
              <Loading />
            </Match>
            <Match when={query.data?.success && query.data.payload.uploaded}>
              <ManifestFields
                manifest={(query.data?.payload as Assets).uploaded!.manifest}
                imagesCount={(query.data?.payload as Assets).uploaded!.imagesTotal}
              />
              <ManifestActionList>
                <ManifestAction level="ok">
                  部署
                </ManifestAction>
                <ManifestAction level="danger">
                  删除
                </ManifestAction>
              </ManifestActionList>
            </Match>
            <Match when={true}>
              <NotFound>
                暂未上传资源
              </NotFound>
            </Match>
          </Switch>
        </Manifest>
      </div>
      <div class="mt-[2rem]">
        <div class="w-full bg-zinc-100 card-edge py-[4rem] text-center">
          <div class="w-fit mx-auto bg-blue-500 rounded shadow-strong px-[2.5rem] py-[1rem] text-white">
            <button class="flex items-center cursor-pointer">
              选择文件
              <Icon inline icon="streamline-plump:file-search-solid" class="ml-[1rem] w-[1.25rem] text-xl" />
            </button>
          </div>
          <p class="mt-[1rem] text-sm text-gray-400 tracking-wider">亦可将验证资源包拖到这里上传</p>
        </div>
      </div>
    </PageBase>
  );
};

const Loading = () => {
  return <p class="my-[2rem] text-gray-400 text-lg text-center">读取中...</p>;
};

const NotFound = (props: { children: JSX.Element }) => {
  return <p class="my-[2rem] text-gray-400 text-lg text-center">{props.children}</p>;
};

const ManifestFields = (props: { manifest: ServerData.Manifest; imagesCount: number }) => {
  return (
    <>
      <ManifestField name="制作日期" value={format(props.manifest.datetime, "yyyy-MM-dd HH:mm:ss")} />
      <ManifestField name="版本" value={props.manifest.version} />
      <ManifestField name="图集数量" value={props.manifest.albums.length} />
      <ManifestField name="图片总数" value={props.imagesCount} />
    </>
  );
};

const Manifest = (props: { title: string; icon: string | IconifyIcon; children: JSX.Element }) => {
  return (
    <div class="w-[26rem] card-edge bg-zinc-100 flex flex-col">
      <h3 class="text-xl font-bold text-center py-[1rem] border-b border-zinc-300/80">
        {props.title}
        <Icon inline icon={props.icon} class="w-[1.25rem] ml-[0.5rem]" />
      </h3>
      {props.children}
    </div>
  );
};

const ManifestField = (props: { name: string; value: string | number }) => {
  return (
    <div class="py-[1rem] hover:bg-zinc-200">
      <p class="text-center text-lg font-medium">{props.name}</p>
      <p class="text-center mt-[0.25rem] text-zinc-500 tracking-wide">{props.value}</p>
    </div>
  );
};

const ManifestAction = (props: { children: JSX.Element; level: "ok" | "normal" | "warning" | "danger" }) => {
  return (
    <button
      class={classNames([
        "text-zinc-50 px-[1.5rem] py-[0.5rem] rounded-lg cursor-pointer transition-colors",
        { "bg-green-500 hover:bg-green-600": props.level === "ok" },
        { "bg-blue-500 hover:bg-blue-600": props.level === "normal" },
        { "bg-yellow-500 hover:bg-yellow-600": props.level === "warning" },
        { "bg-red-500 hover:bg-red-600": props.level === "danger" },
      ])}
    >
      {props.children}
    </button>
  );
};

const ManifestActionList = (props: { children: JSX.Element }) => {
  return (
    <div class="flex justify-center gap-[1rem] p-[1rem] border-t border-zinc-300/80">
      {props.children}
    </div>
  );
};
