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
  // 如果数组长度为 1，直接返回。
  if (array.length == 1) return [element];
  // 如果要更新的元素在最前面，插入到头部。
  if (index === 0) {
    return [element, ...array.slice(1, array.length)];
  }
  // 如果要更新的元素在最前面，插入到尾部。
  if (index === array.length - 1) {
    return [...array.slice(0, array.length - 1), element];
  }
  const newArray = [];
  // 插入数组头部
  newArray.push(...array.slice(0, index));
  // 插入已更新的元素
  newArray.push(element);
  // 追加数组尾部
  newArray.push(...array.slice(index + 1, array.length));

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
