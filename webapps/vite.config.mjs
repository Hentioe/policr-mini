import process from "node:process";
import { defineConfig } from "vite";
import solid from "vite-plugin-solid";

export default defineConfig(({ mode }) => {
  // The development mode starts a watcher, we need to listen to stdin to avoid orphan processes.
  if (mode === "development") {
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
    build: {
      outDir: "../priv/static",
      emptyOutDir: false, // 不要清空，因为同时存在旧 webpack 构建的项目
      rollupOptions: {
        input: {
          console: "./src/console/main.tsx",
        },
        output: {
          entryFileNames: "assets/[name].js", // remove hash
          chunkFileNames: "assets/[name].js",
          assetFileNames: "assets/[name][extname]",
        },
      },
    },
  };
});
