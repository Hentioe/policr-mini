import fetch from "unfetch";
import camelize from "camelcase-keys";
import { toast } from "react-toastify";
import "lodash";

const getFetcher = (...args) =>
  fetch(...args).then((resp) => camelizeJson(resp));

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
    resp
      .json()
      .then((json) =>
        json.errors ? resolve(json) : resolve(camelize(json, { deep: true }))
      )
  );
}

function toastMessage(message, { type } = {}) {
  switch (type) {
    case "error":
      toast.error(message, {
        position: "bottom-center",
        autoClose: 2500,
        hideProgressBar: false,
        closeOnClick: true,
        pauseOnHover: true,
        draggable: true,
        progress: undefined,
      });
      break;
    case "warn":
      toast.warn(message, {
        position: "bottom-center",
        autoClose: 2000,
        hideProgressBar: false,
        closeOnClick: true,
        pauseOnHover: true,
        draggable: true,
        progress: undefined,
      });
      break;
    default:
      toast.info(message, {
        position: "bottom-center",
        autoClose: 1500,
        hideProgressBar: false,
        closeOnClick: true,
        pauseOnHover: true,
        draggable: true,
        progress: undefined,
      });
      break;
  }
}

const sysPages = [
  "profile",
  "managements",
  "logs",
  "tasks",
  "terms",
  "terminal",
  "third_parties",
  "sponsorship",
];

function isSysLink({ path, page }) {
  if (!path) throw "The `path` argument is missing";
  if (page) {
    const re = new RegExp(`^/admin/sys/${page}`);
    return re.test(path);
  } else {
    for (let i = 0; i < sysPages.length; i++) {
      const page = sysPages[i];
      // 任其一匹配则为 `true`
      if (isSysLink({ path: path, page: page })) return true;
    }
    return false;
  }
}

function errorsToString(errors) {
  if (Object.keys(errors).length == 1 && errors.hasOwnProperty("description")) {
    return errors.description.join(",") + ".";
  }

  let message = "";

  Object.entries(errors).forEach(([key, value]) => {
    message += key + " " + value.join(",");
  });

  return message + ".";
}

function toastErrors(errors) {
  toastMessage(errorsToString(errors), { type: "error" });
}

export {
  getFetcher,
  getIdFromLocation,
  updateInNewArray,
  camelizeJson,
  isSysLink,
  toastMessage,
  toastErrors,
  errorsToString,
};
