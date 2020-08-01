import camelize from "camelcase-keys";
import { toast } from "react-toastify";
import "lodash";

function getIdFromLocation(location) {
  const re = /^\/admin\/chats\/(-\d+)\//i;
  const found = location.pathname.match(re);
  if (found && found.length == 2) {
    const [, id] = found;
    return id;
  }

  return null;
}

function updateInNewArray(array, element, index) {
  // 如果要更新的元素不在中间，直接克隆并更新
  if (index === 0 || index === array.length - 1) {
    const newArray = [...array];
    newArray[index] = element;
    return newArray;
  }
  const newArray = [];
  // 如果编辑的不是第一个，插入数组头部
  if (index > 0) newArray.push(...array.slice(0, index));
  // 插入要更新的元素
  newArray.push({ ...array[index], ...element });
  // 如果编辑的不是最后一个，追加数组尾部
  if (index < array.length - 1)
    newArray.push(...array.slice(index, array.length - 1));

  return newArray;
}

function camelizeJson(resp) {
  return new Promise((resolve) =>
    resp.json().then((json) => resolve(camelize(json, { deep: true })))
  );
}

function toastError(message) {
  toast.error(message, {
    position: "bottom-center",
    autoClose: 2500,
    hideProgressBar: false,
    closeOnClick: true,
    pauseOnHover: true,
    draggable: true,
    progress: undefined,
  });
}

const noAnyPermissionsError = {
  description: ["does not have any permissions"],
};
function isNoPermissions(data) {
  if (!data.errors) return false;

  return _.isEqual(noAnyPermissionsError, data.errors);
}

export {
  getIdFromLocation,
  updateInNewArray,
  camelizeJson,
  toastError,
  isNoPermissions,
};
