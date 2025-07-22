import { useQuery } from "@tanstack/solid-query";
import classNames from "classnames";
import { createEffect, createSignal, Match, onMount, Switch } from "solid-js";
import { deleteTerm, getTerm, previewTerm, saveTerm } from "../api";
import { ActionButton } from "../components";
import { PageBase } from "../layouts";
import { setPage } from "../state/global";
import { setTitle } from "../state/meta";
import { toaster } from "../utils";

export default () => {
  const [editingContent, setEditingContent] = createSignal("");
  const [isSaving, setIsSaving] = createSignal(false);
  const [isPreviewing, setIsPreviewing] = createSignal(false);
  const [isDeleting, setIsDeleting] = createSignal(false);
  const query = useQuery(() => ({
    queryKey: ["term"],
    queryFn: getTerm,
    refetchOnWindowFocus: false, // 避免未保存的内容被覆盖
    refetchOnReconnect: false, // 同上
  }));

  const handleContentChange = (e: Event) => {
    const target = e.target as HTMLTextAreaElement;
    setEditingContent(target.value);
  };

  const handleSave = async () => {
    setIsSaving(true);
    const resp = await saveTerm(editingContent());
    if (resp.success) {
      toaster.success({ title: "保存成功", description: "用户条款已更新" });
      query.refetch();
    } else {
      toaster.error({ title: "保存失败", description: resp.message });
    }
    setIsSaving(false);
  };

  const handlePreview = async () => {
    setIsPreviewing(true);
    const resp = await previewTerm(editingContent());
    if (resp.success) {
      toaster.success({ title: "已创建预览", description: "请留意机器人的私聊消息" });
    } else {
      toaster.error({ title: "预览失败", description: resp.message });
    }
    setIsPreviewing(false);
  };

  const handleDelete = async () => {
    setIsDeleting(true);
    const resp = await deleteTerm();
    if (resp.success) {
      toaster.success({ title: "删除成功", description: "使用条款已删除" });
      query.refetch();
    } else {
      toaster.error({ title: "删除失败", description: resp.message });
    }
    setIsDeleting(false);
  };

  createEffect(() => {
    if (query.data?.success) {
      setEditingContent(query.data.payload.content || "");
    }
  });

  onMount(() => {
    setTitle("使用条款");
    setPage("terms");
  });

  return (
    <PageBase>
      <textarea
        value={editingContent()}
        onChange={handleContentChange}
        placeholder="请输入用户条款内容..."
        class="w-full h-[34rem] card-edge focus:outline-2 focus:outline-blue-400 p-[1rem]"
      >
        {query.data?.success && query.data.payload.content}
      </textarea>
      <div class="mt-[0.5rem]">
        <div class="flex gap-[1.5rem] justify-center">
          <ActionButton onClick={handleSave} loading={isSaving()} variant="info" size="lg" icon="material-symbols:save">
            保存
          </ActionButton>
          <ActionButton
            onClick={handlePreview}
            loading={isPreviewing()}
            disabled={isSaving()}
            variant="info"
            size="lg"
            icon="mdi:eye"
            outline
          >
            预览
          </ActionButton>
          <ActionButton
            onClick={handleDelete}
            loading={isDeleting()}
            disabled={isSaving()}
            variant="danger"
            size="lg"
            icon="mdi:delete"
          >
            删除
          </ActionButton>
        </div>
      </div>
      <div
        class={classNames([
          "mt-[1rem] py-[1rem] text-sm text-gray-500 tracking-wider transition-colors card-edge",
          { "bg-blue-200": editingContent() !== "" },
          { "bg-red-200": editingContent() === "" },
        ])}
      >
        <Switch>
          <Match when={editingContent()}>
            <p class="text-center">
              使用条款消息将发送到初次拉入的群组中。
            </p>
          </Match>
          <Match when={true}>
            <p class="text-center">
              当条款内容为空时，将不会发送使用条款消息。
            </p>
          </Match>
        </Switch>
      </div>
    </PageBase>
  );
};
