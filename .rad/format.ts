import type { Task } from "./common.ts";

export const format: Task = {
  async fn({ sh }) {
    const cmds = [
      `deno fmt rad.ts ui/src .rad`,
      `cargo fmt --all`,
    ];
    await Promise.all(cmds.map((cmd) => sh(cmd)));
  },
};
