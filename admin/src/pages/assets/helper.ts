export function setupDragAndDrop(dropAreaEl: HTMLDivElement, fileInputEl: HTMLInputElement) {
  // 拖拽事件
  ["dragenter", "dragover", "dragleave", "drop"].forEach(eventName => {
    dropAreaEl.addEventListener(eventName, preventDefaults, false);
  });

  function preventDefaults(e: Event) {
    e.preventDefault();
    e.stopPropagation();
  }

  ["dragenter", "dragover"].forEach(eventName => {
    dropAreaEl.addEventListener(eventName, () => {
      dropAreaEl.classList.add("dragover");
    }, false);
  });

  ["dragleave", "drop"].forEach(eventName => {
    dropAreaEl.addEventListener(eventName, () => {
      dropAreaEl.classList.remove("dragover");
    }, false);
  });

  dropAreaEl.addEventListener("drop", (e) => {
    const dt = e.dataTransfer;
    const files = dt?.files || null;
    fileInputEl.files = files;
    // 手动触发文件输入的 change 事件，以启动上传
    fileInputEl.dispatchEvent(new Event("change", { bubbles: true }));
  }, false);
}
