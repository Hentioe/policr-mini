import { defineConfig } from "vite";
import solid from "vite-plugin-solid";

export default defineConfig(({ command }) => {
  const isDev = command !== "build";
  if (isDev) {
    // Terminate the watcher when Phoenix quits
    process.stdin.on("close", () => {
      process.exit(0);
    });

    process.stdin.resume();
  }

  return {
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
  };
});
