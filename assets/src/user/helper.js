import camelize from "camelcase-keys";

function camelizeJson(resp) {
  return new Promise((resolve) =>
    resp
      .json()
      .then((json) =>
        json.errors ? resolve(json) : resolve(camelize(json, { deep: true }))
      )
  );
}

function errorsToString(errors) {
  if (Object.keys(errors).length == 1 && errors.hasOwnProperty("description")) {
    return errors.description.join("，") + "。";
  }

  let message = "";

  Object.entries(errors).forEach(([key, value]) => {
    message += key + " " + value.join("，");
  });

  return message + "。";
}

export { camelizeJson, errorsToString };
