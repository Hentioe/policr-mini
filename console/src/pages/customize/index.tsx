import { destructure } from "@solid-primitives/destructure";
import { useQuery } from "@tanstack/solid-query";
import { createSignal, Index, onMount, Show } from "solid-js";
import { createStore, produce, unwrap } from "solid-js/store";
import { deleteCustom, getCustoms, saveCustom } from "../../api";
import { ActionButton } from "../../components";
import Checkbox from "../../components/Checkbox";
import FullscreenDialog from "../../components/ContentDialog";
import { PageBase } from "../../layouts";
import { globalState } from "../../state";
import { setCurrentPage } from "../../state/global";
import { setTitle } from "../../state/meta";
import { toaster } from "../../utils";
import { Adding } from "./Adding";
import List from "./List";

type CustomItem = ServerData.CustomItem;
const DEFAULT_ANSWERS = [{ text: "", correct: false }];

export default () => {
  const { currentChatId } = destructure(globalState);
  const [deleting, setDeleting] = createSignal<number[]>([]);
  const [isEditing, setIsEditing] = createSignal<boolean>(false);
  const [editingId, setEditingId] = createSignal<number | null>(null);
  const [editingTitle, setEditingTitle] = createSignal<string>("");
  const [editingHasAttachment, setEditingHasAttachment] = createSignal<boolean>(false);
  const [editingAttachment, setEditingAttachment] = createSignal<string>("");
  const [editingAnswers, setEditingAnswers] = createStore<ServerData.CustomItemAnswer[]>(
    structuredClone(DEFAULT_ANSWERS),
  );
  const [isSaving, setIsSaving] = createSignal<boolean>(false);

  const query = useQuery(() => ({
    queryKey: ["customs", currentChatId()],
    queryFn: () => getCustoms(currentChatId()!),
    enabled: currentChatId() != null,
  }));

  const handleDelete = async (id: number) => {
    setDeleting((prev) => [...prev, id]);
    const resp = await deleteCustom(id);
    setDeleting((prev) => prev.filter((item) => item !== id));

    if (resp.success) {
      toaster.success({ title: "删除成功", description: `自定义验证「${resp.payload.title}」已删除` });
      query.refetch();
    } else {
      toaster.error({ title: "删除失败", description: resp.message });
    }
  };

  const handleEdit = (item: CustomItem) => {
    setEditingId(item.id);
    setEditingTitle(item.title);
    setEditingHasAttachment(!!item.attachment);
    setEditingAttachment(item.attachment || "");
    setEditingAnswers(structuredClone(unwrap(item.answers)) || []);
    setIsEditing(true);
  };

  const handleEditClose = () => {
    setIsEditing(false);
    setEditingId(null);
    setEditingTitle("");
    setEditingHasAttachment(false);
    setEditingAttachment("");
    setEditingAnswers(structuredClone(DEFAULT_ANSWERS));
  };

  const handleAttachmentInput = (value: string) => setEditingAttachment(value);
  const handleTitleInput = (value: string) => setEditingTitle(value);

  const handleAnswerInput = (index: number, value: string) => {
    setEditingAnswers(produce((draft) => {
      draft[index].text = value;
    }));
  };

  const handleAnswerCorrectChange = (index: number, isCorrect: boolean) => {
    setEditingAnswers(produce((draft) => {
      draft[index].correct = isCorrect;
    }));
  };

  const handleAddAnswer = () => {
    setEditingAnswers((prev) => [...prev, { text: "", correct: false }]);
  };

  const handleSave = async () => {
    setIsSaving(true);
    const castAnswer = ({ text, correct }: ServerData.CustomItemAnswer) => {
      if (correct) {
        return "+" + text;
      } else {
        return "-" + text;
      }
    };
    const resp = await saveCustom({
      id: editingId(),
      custom: {
        chatId: currentChatId(),
        title: editingTitle(),
        answers: editingAnswers.map(castAnswer),
        attachment: editingHasAttachment() ? editingAttachment() : null,
      },
    });
    setIsSaving(false);

    if (resp.success) {
      toaster.success({ title: "保存成功", description: `自定义验证「${resp.payload.title}」已保存` });
      await query.refetch();
      handleEditClose();
    } else {
      toaster.error({ title: "保存失败", description: resp.message });
    }
  };

  const handlePreview = () => {
    toaster.warning({ title: "预览功能尚未实现", description: "请关注后续更新。" });
  };

  const EditButton = (props: { item: CustomItem }) => {
    return (
      <ActionButton variant="info" icon="uil:edit" onClick={() => handleEdit(props.item)}>
        编辑
      </ActionButton>
    );
  };

  const DeleteButton = (props: { id: number }) => {
    return (
      <ActionButton
        onClick={() => handleDelete(props.id)}
        loading={deleting().includes(props.id)}
        variant="danger"
        icon="lets-icons:del-alt-fill"
      >
        删除
      </ActionButton>
    );
  };

  const PreviewButton = () => {
    return (
      <ActionButton variant="info" icon="mdi:eye" outline onClick={handlePreview}>
        预览
      </ActionButton>
    );
  };

  onMount(() => {
    setCurrentPage("customize");
    setTitle("自定义");
  });

  return (
    <PageBase>
      <div class="bg-white">
        <ActionButton onClick={() => setIsEditing(true)} variant="info" outline fullWidth>
          添加自定义验证
        </ActionButton>
        <List.Root items={query.data?.success && query.data.payload || []}>
          {(item) => (
            <List.Item.Root
              item={item}
              buttons={[<DeleteButton id={item.id} />, <EditButton item={item} />, <PreviewButton />]}
            />
          )}
        </List.Root>
      </div>
      <FullscreenDialog open={isEditing()} title="编辑" onClose={handleEditClose}>
        <div>
          <Adding.Root>
            <Adding.Field label="标题">
              <Adding.Input placeholder="输入问题标题" value={editingTitle()} onInput={handleTitleInput} />
            </Adding.Field>
            <Show when={editingHasAttachment()}>
              <Adding.Field label="附件">
                <Adding.Input
                  placeholder="私聊机器人任意文件获取此值"
                  value={editingAttachment()}
                  onInput={handleAttachmentInput}
                />
              </Adding.Field>
            </Show>
            <Index each={editingAnswers}>
              {(answer, i) => (
                <Adding.Answer
                  label={`答案${i + 1}`}
                  value={answer().text}
                  onInput={(value) => handleAnswerInput(i, value)}
                  onCorrectChange={(isCorrect) => handleAnswerCorrectChange(i, isCorrect)}
                  correct={answer().correct}
                />
              )}
            </Index>
          </Adding.Root>
          <div class="mt-[1rem]">
            <ActionButton onClick={handleAddAnswer} fullWidth outline>
              继续增加答案
            </ActionButton>
          </div>
          <div class="mt-[0.5rem]">
            <Checkbox label="包含附件？" checked={editingHasAttachment()} onChange={setEditingHasAttachment} />
          </div>
          <div class="mt-[1rem] flex justify-between gap-[1rem]">
            <ActionButton onClick={handlePreview} variant="info" size="lg" icon="mdi:eye" fullWidth outline>
              预览
            </ActionButton>
            <ActionButton
              onClick={handleSave}
              loading={isSaving()}
              variant="info"
              size="lg"
              icon="material-symbols:save"
              fullWidth
            >
              保存
            </ActionButton>
          </div>
        </div>
      </FullscreenDialog>
    </PageBase>
  );
};
