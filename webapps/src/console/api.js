import camelize from "camelcase-keys";

const camelizeJson = (resp) => {
  return new Promise((resolve) =>
    resp
      .json()
      .then((json) => json.errors ? resolve(json) : resolve(camelize(json, { deep: true })))
  );
};

// TODO: 等待后端启用 CSRF 保护
// const csrfToken = document.querySelector("meta[name=csrf-token]").content;

const builder = (url, method, body) =>
  fetch(url, {
    credentials: "same-origin",
    method: method,
    headers: { "Content-Type": "application/json" /* "x-csrf-token": csrfToken */ },
    body: body && JSON.stringify(body),
  }).then((resp) => camelizeJson(resp));

const getter = (url) => builder(url, "GET");
const puter = (url, body = null) => builder(url, "PUT", body);
const deleter = (url, body = null) => builder(url, "DELETE", body);
const poster = (url, body = null) => builder(url, "POST", body);

export { deleter, getter, poster, puter };
