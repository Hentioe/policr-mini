export function getPaginationPages(page: number, pageSize: number, total: number): number[] {
  const totalPages = Math.ceil(total / pageSize);

  if (totalPages <= 5) {
    return Array.from({ length: totalPages }, (_, i) => i + 1);
  }

  let start = Math.max(1, page - 2);
  let end = Math.min(totalPages, page + 2);

  // 当前面不足2个时，向后补充
  if (start === 1) {
    end = Math.min(totalPages, start + 4);
  }

  // 当后面不足2个时，向前补充
  if (end === totalPages) {
    start = Math.max(1, end - 4);
  }

  return Array.from({ length: end - start + 1 }, (_, i) => start + i);
}
