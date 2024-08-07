import type { Task } from "./common.ts";

export const deploy: Task = {
  dependsOn: [],
  async fn({ sh, logger }) {
    const ip = Deno.env.get("NAS_IP");
    const sshUser = "cdaringe";
    if (!ip) throw new Error(`missing NAS_IP env var`);
    const destDir = "/volume1/docker/freshawair";
    const ssh = (...args: string[]) => `ssh ${ip} -- ${args.join(" ")}`;
    await ssh(`mkdir -p ${destDir}`);
    logger.info("syncing");
    await sh(
      [
        `rsync -av`,
        `--exclude-from=".rsyncignore"`,
        `${Deno.cwd()}/`,
        `${sshUser}@${ip}:${destDir}/`,
      ].join(" "),
    );
    const cmd = [
      `cd ${destDir}`,
      "/usr/local/bin/docker-compose down",
      "/usr/local/bin/docker-compose build",
      "mkdir -p ../.freshdb", // put the db in a parent dir for write protection :|
      "mkdir -p ../.freshdb_grafanadb",
      "/usr/local/bin/docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d --force-recreate",
    ].join(" && ");
    const remoteCmd = `echo '${cmd}' | ssh ${sshUser}@${ip}`;
    logger.info(remoteCmd);
    await sh(remoteCmd, { logger });
  },
};
