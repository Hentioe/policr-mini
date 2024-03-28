import { defineConfig } from "vite";
import solid from "vite-plugin-solid";

export default defineConfig({
  plugins: [
    solid({
      babel: {
        plugins: [
          "babel-plugin-twin", // 省略 `import tw from "twin.macro"`
          "babel-plugin-macros",
        ],
      },
    }),
  ],
});
