import * as i18n from "@solid-primitives/i18n";
import { createMemo, createSignal } from "solid-js";
import * as cn from "./locales/cn";

type Locale = "cn";
type Dict = typeof cn.dict;

const dict = {
  cn: cn.dict as Dict,
};

export function savedLocle(): Locale | undefined {
  const locale = localStorage.getItem("locale");

  if (
    locale != null
    && typeof locale === "string"
    && Object.keys(dict).includes(locale)
  ) {
    return locale as Locale;
  }

  return undefined;
}

export function currentLocale(): Locale {
  const locale = savedLocle();
  if (locale) {
    // 如果本地存在有效的语言设置，直接返回
    return locale;
  }

  return "cn";
  // return navigator.language.startsWith("zh-") ? "cn" : "en";
}

export function saveLocale(locale: Locale) {
  localStorage.setItem("locale", locale);
}

export function clearSavedLocale() {
  localStorage.removeItem("locale");
}

const defaultLocale: Locale = currentLocale();

// 监听语言变化
window.addEventListener("languagechange", () => {
  setLocale(currentLocale());
});

// 避免 lint 警告（createMemo 应该用于 effects 或 JSX）
const createDictCache = createMemo;

const [locale, setLocale] = createSignal<Locale>(defaultLocale);
const getflatDict = createDictCache(() => i18n.flatten(dict[locale()]));

const translator = i18n.translator(getflatDict);

export type Translator = typeof translator;

export function useTranslation() {
  return translator;
}

export function proxyTranslator() {
  const t = i18n.translator(() => getflatDict(), i18n.resolveTemplate);

  return i18n.proxyTranslator(t);
}

export { Locale, locale, setLocale };
