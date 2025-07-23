import { Icon } from "@iconify-icon/solid";
import { useQuery } from "@tanstack/solid-query";
import { createSignal, Match, onMount, Switch } from "solid-js";
import { deleteUploadedAlbums, deployUploadedAlbums, getAssets, uploadAlbums } from "../../api";
import { ActionButton } from "../../components";
import { PageBase } from "../../layouts";
import { setPage } from "../../state/global";
import { setTitle } from "../../state/meta";
import { toaster } from "../../utils";
import { Manifest } from "./Manifest";
import Loading from "./Loading";
import NotFound from "./NotFound";
import { setupDragAndDrop } from "./helper";

type Assets = ServerData.Assets;

export default () => {
  const [fileEl, setFileEl] = createSignal<HTMLInputElement | null>(null);
  const [dropAreaEl, setDropAreaEl] = createSignal<HTMLDivElement | null>(null);
  const [selectedFile, setSelectedFile] = createSignal<File | null>(null);
  const [isDeleting, setIsDeleting] = createSignal<boolean>(false);
  const [isDeploying, setIsDeploying] = createSignal<boolean>(false);
  const [uploadProgress, setUploadProgress] = createSignal<number>(0);
  const [uploadError, setUploadError] = createSignal<string | null>(null);

  const query = useQuery(() => ({
    queryKey: ["assets"],
    queryFn: getAssets,
  }));

  const handleDeleteUploaded = async () => {
    setIsDeleting(true);
    const resp = await deleteUploadedAlbums();
    setIsDeleting(false);
    if (resp.success) {
      toaster.success({ title: "删除成功", description: "已删除上传的资源" });
      query.refetch();
    } else {
      toaster.error({ title: "删除失败", description: resp.message });
    }
  };

  const handleDeployUploaded = async () => {
    setIsDeploying(true);
    const resp = await deployUploadedAlbums();
    setIsDeploying(false);
    if (resp.success) {
      toaster.success({ title: "部署成功", description: "已部署上传的资源" });
      query.refetch();
    } else {
      toaster.error({ title: "部署失败", description: resp.message });
    }
  };

  const handleClearDeployed = async () => {
    toaster.error({ title: "功能未实现", description: "尚未实现对已部署资源的清空" });
  };

  const openFileSelector = () => {
    const input = fileEl();

    if (input) {
      input.click();
    }
  };

  const handleFileChange = async () => {
    const input = fileEl();

    if (input) {
      const files = input.files;
      if (files && files.length > 0) {
        const file = files[0];
        setUploadError(null);
        setSelectedFile(file);

        const resp = await uploadAlbums(file, (progressEvent) => {
          if (progressEvent.lengthComputable && progressEvent.total !== undefined) {
            const percent = Math.round(
              (progressEvent.loaded / progressEvent.total!) * 100,
            );

            setUploadProgress(percent);
          }
        });

        if (resp.success) {
          await query.refetch();
          setSelectedFile(null);
          input.value = ""; // 清空文件输入
          setUploadProgress(0);
        } else {
          setUploadError(resp.message);
          input.value = ""; // 清空文件输入
        }
      }
    }
  };

  onMount(() => {
    setTitle("验证资源");
    setPage("assets");

    const dropArea = dropAreaEl();
    const fileInput = fileEl();

    if (dropArea && fileInput) {
      setupDragAndDrop(dropArea, fileInput);
    }
  });

  return (
    <PageBase>
      <div class="flex justify-between">
        <Manifest.Root title="已部署的资源" icon="flat-color-icons:ok">
          <Switch>
            <Match when={query.isLoading}>
              <Loading />
            </Match>
            <Match when={query.data?.success && query.data.payload.deployed}>
              <Manifest.Fields
                manifest={(query.data?.payload as Assets).deployed!.manifest}
                imagesCount={(query.data?.payload as Assets).deployed!.imagesTotal}
              />
              <Manifest.ActionList>
                <ActionButton onClick={handleClearDeployed} size="lg" variant="danger" icon="tdesign:clear-filled">
                  清空
                </ActionButton>
              </Manifest.ActionList>
            </Match>
            <Match when={true}>
              <NotFound>
                暂未部署资源
              </NotFound>
            </Match>
          </Switch>
        </Manifest.Root>
        <Manifest.Root title="已上传的资源" icon="emojione-v1:warning">
          <Switch>
            <Match when={query.isLoading}>
              <Loading />
            </Match>
            <Match when={query.data?.success && query.data.payload.uploaded}>
              <Manifest.Fields
                manifest={(query.data?.payload as Assets).uploaded!.manifest}
                imagesCount={(query.data?.payload as Assets).uploaded!.imagesTotal}
              />
              <Manifest.ActionList>
                <ActionButton
                  onClick={handleDeployUploaded}
                  loading={isDeploying()}
                  size="lg"
                  variant="success"
                  icon="flowbite:cloud-arrow-up-solid"
                >
                  部署
                </ActionButton>
                <ActionButton
                  onClick={handleDeleteUploaded}
                  loading={isDeleting()}
                  size="lg"
                  variant="danger"
                  icon="ic:baseline-delete"
                >
                  删除
                </ActionButton>
              </Manifest.ActionList>
            </Match>
            <Match when={true}>
              <NotFound>
                暂未上传资源
              </NotFound>
            </Match>
          </Switch>
        </Manifest.Root>
      </div>
      <div class="mt-[2rem]">
        <div
          ref={setDropAreaEl}
          class="w-full bg-card card-edge pt-[4rem] pb-[1rem] text-center transition-transform"
        >
          <button
            class="mx-auto bg-blue-500 px-[2.5rem] py-[1rem] text-white rounded shadow-strong flex items-center cursor-pointer"
            onClick={openFileSelector}
          >
            选择文件
            <Icon inline icon="streamline-plump:file-search-solid" class="ml-[1rem] w-[1.25rem] text-xl" />
          </button>
          <input type="file" ref={setFileEl} onChange={handleFileChange} class="hidden" multiple />
          <div class="mt-[1rem] h-[4rem]">
            <Switch>
              <Match when={uploadError()}>
                <p class="text-center text-red-400">上传失败：{uploadError()}</p>
              </Match>
              <Match when={selectedFile()}>
                <p class="mt-[1rem] text-sm text-gray-600">
                  正在上传文件：{selectedFile()!.name}
                </p>
                <p class="mt-[0.5rem] text-gray-500">
                  {uploadProgress()}%
                </p>
              </Match>
              <Match when={true}>
                <p class="text-sm text-gray-400 tracking-wider">亦可将验证资源包拖到这里上传</p>
              </Match>
            </Switch>
          </div>
        </div>
      </div>
    </PageBase>
  );
};
