import type { Task, Tasks } from "https://deno.land/x/rad@v4.1.1/src/mod.ts";
import { Client } from "https://deno.land/x/postgres@v0.4.5/mod.ts";
import type { ConnectionOptions } from "https://deno.land/x/postgres@v0.4.5/connection_params.ts";

const armImageName = "armocaml";
const armDockerImageTag = "cdaringe/freshawair:arm";

// db
const containerName = "freshawair_freshdb_1";
const dbname = "fresh";
const dbuser = "fresh";
const createClient = async () => {
  const pg = new Client({
    user: `${dbuser}`,
    hostname: `127.0.0.1`,
    database: `${dbname}`,
    password: `${dbuser}`,
    port: 5432,
  });
  await pg.connect();
  return pg;
};

// opam
const opamSetup: Task = {
  async fn({ sh }) {
    try {
      await sh(`opam switch freshawair`);
    } catch (err) {
      await sh(`opam switch create freshawair 4.10.1`);
    }
  },
};
const opamInstall: Task = {
  dependsOn: [opamSetup],
  fn: async ({ sh }) => sh(`bash ./opam.lame.deps.sh`),
};
const opamExport: Task = `opam switch export freshawair.opam.deps`;
const opamImport: Task = `opam switch import freshawair.opam.deps`;

// tasks
const dbi = `docker build -t ${armImageName} .`;
const format: Task = {
  async fn({ sh }) {
    const cmds = [
      `deno fmt rad.ts`,
      `opam exec -- dune build @fmt --auto-promote`,
    ];
    await Promise.all(cmds.map((cmd) => sh(cmd)));
  },
};

const startAgent: Task = `opam exec -- dune exec bin/Agent.exe`;
const startServer: Task = `AUTH_TOKEN=tacos opam exec -- dune exec bin/Server.exe`;
const buildArmImage: Task = {
  fn: async ({ sh }) => {
    const progressArg = "--progress plain";
    const commands = [
      `docker buildx build ${progressArg} --platform linux/arm/v7 -f Dockerfile.agent -t ${armDockerImageTag} . --load`,
    ];
    for (const cmd of commands) await sh(cmd);
  },
};
const extractArmBin: Task = {
  dependsOn: [buildArmImage],
  async fn({ sh, logger }) {
    const cmds = [
      `docker create --name extract ${armDockerImageTag}`,
      `docker cp extract:/app/_build/default/bin/Fresh.exe  ./fresh.arm`,
    ];
    try {
      for (const cmd of cmds) await sh(cmd);
    } finally {
      await sh(`docker rm extract`).catch((err) => {
        logger.warning(err);
      });
    }
  },
};
const buildArm: Task = {
  dependsOn: [buildArmImage, extractArmBin],
};

const buildServerImage: Task = {
  async fn({ sh }) {
    const progressArg = "--progress plain";
    await sh(
      `docker buildx build ${progressArg} --platform linux/amd64  -f Dockerfile.server -t cdaringe/freshawair-server .`
    );
  },
};
export const tasks: Tasks = {
  ...{
    sa: `${startAgent} -- -data-store-endpoint http://localhost:8000/air/stats -poll-duration 10 -auth-token tacwfos`,
  },
  ...{ ss: startServer },
  ...{ f: format, format },
  ...{ opamInstall, opamSetup },
  opam: opamInstall,
  export: opamExport,
  import: opamImport,
  // db crap
  db: {
    fn: async ({ sh }) => {
      await sh(`docker-compose down freshdb -f`).catch(() => {});
      await sh(`docker-compose up freshdb`).catch(() => {});
    },
  },
  "db:seed": {
    fn: async ({ sh }) => {
      const copyQ = "-c '\\copy sensor_stats from STDIN with(format csv)'";
      await sh(
        `rad db:emitseeddata | docker exec -i ${containerName} psql -U ${dbname} ${dbuser} ${copyQ}`
      );
    },
  },
  "db:emitseeddata": {
    fn() {
      function addDays(date: Date, days: number) {
        var result = new Date(date);
        result.setDate(result.getDate() + days);
        return result;
      }
      const getRandDayOffset = () => Math.random() * 365;
      let i = 525_600; // minutes in a year
      while (i) {
        const vals: any[] = Array.from(Array(14)).map(() => Math.random());
        vals[9] = addDays(new Date(), getRandDayOffset()).toISOString();
        console.log(`${vals.join(",")}`);
        --i;
      }
    },
  },
  psql: {
    fn: async ({ sh }) => {
      await sh(`psql -h 127.0.0.1 -U ${dbname} ${dbuser}`);
    },
  },
  // arm crap
  // https://github.com/ocaml/infrastructure/wiki/Containers
  "arm:shell":
    "docker run -it --rm --entrypoint /bin/bash --platform linux/arm/v7 ocaml/opam2:debian-stable",
  buildArmImage,
  extractArmBin,
  ...{ ba: buildArm, "build:arm": buildArm },
  // server image
  ...{ buildServerImage, bsi: buildServerImage },
};
