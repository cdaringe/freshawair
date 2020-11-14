import { copy } from "https://deno.land/std/fs/mod.ts";
import type { Task } from "./common.ts";
import { tasks as ui } from "./ui.ts";

export const deploy: Task = {
  dependsOn: [ui.uibuild],
  async fn({ sh, logger }) {
    const ip = Deno.env.get("NAS_IP");
    const user = Deno.env.get("USER");
    if (!ip) throw new Error(`missing NAS_IP env var`);
    const destDir = "/volume1/docker/freshawair";
    await Deno.remove("public", { recursive: true }).catch(() => {});
    await copy("ui/build/", "public");
    const ssh = (...args: string[]) => `ssh ${ip} -- ${args.join(" ")}`;
    await ssh(`mkdir -p ${destDir}`);
    logger.info("syncing");
    await sh([
      `rsync -av`,
      `--exclude-from=".rsyncignore"`,
      `${Deno.cwd()}/`,
      `${ip}:${destDir}/`,
    ].join(" "));
    const cmd = [
      `cd ${destDir}`,
      "/usr/local/bin/docker-compose down",
      "/usr/local/bin/docker-compose build --parallel",
      "/usr/local/bin/docker-compose up -d --force-recreate",
    ].join(" && ");
    await sh(`echo '${cmd}' | ssh ${ip}`, { logger });
  },
};
