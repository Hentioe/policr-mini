import tailwindcss from "@tailwindcss/vite";
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
      solid(),
      tailwindcss(),
    ],
    build: {
      outDir: "../priv/static",
      emptyOutDir: false,
      rollupOptions: {
        input: {
          console_v2: "./src/main.tsx",
        },
        output: {
          entryFileNames: "assets/[name].js", // remove hash
          chunkFileNames: "assets/[name].js",
          assetFileNames: "assets/[name][extname]",
        },
      },
      assetsInlineLimit: 4096, // 4KB 以内允许内联
    },
  };
});
