import type { Task, Tasks } from "./common.ts";

const uiScriptMap: Record<string, string> = JSON.parse(
  Deno.readTextFileSync("ui/package.json"),
).scripts;
export const tasks: Tasks = Object.entries(uiScriptMap).reduce(
  (acc, [key, cmd]) => {
    const task: Task = `cd ui && yarn ${cmd}`;
    return { ...acc, [`ui${key}`]: task };
  },
  {} as Tasks,
);
