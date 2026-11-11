import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    // در حالت توسعه (npm run dev) درخواست‌های same-origin به سرور بک‌اند منتقل می‌شوند
    proxy: {
      "/api": {
        target: "http://127.0.0.1:8000",
        changeOrigin: true,
      },
      "/slot-times": {
        target: "http://127.0.0.1:8000",
        changeOrigin: true,
      },
    },
  },
});
