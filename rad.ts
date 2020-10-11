import type {
  Task,
  Tasks,
} from "https://deno.land/x/rad@v4.1.1/src/mod.ts";
import { Client } from "https://deno.land/x/postgres@v0.4.5/mod.ts";
import type { ConnectionOptions } from "https://deno.land/x/postgres@v0.4.5/connection_params.ts";

const armImageName = "armocaml";
const armDockerImageTag = "cdaringe/freshawair:arm";

// db
const containerName = "freshawairdb";
const dbname = "fresh";
const dbuser = "fresh";
const dbSuperUser = "postgres";
const dbSuperPassword = dbSuperUser;
type CreateClient = { asSuper?: boolean } & Partial<ConnectionOptions>;
const createClient = async (
  { asSuper, ...rest }: CreateClient,
) => {
  const pg = new Client({
    user: `${asSuper ? dbSuperUser : dbuser}`,
    hostname: `127.0.0.1`,
    database: `${dbname}`,
    password: `${asSuper ? dbSuperUser : dbuser}`,
    port: 5432,
    ...rest,
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
      `dune build @fmt --auto-promote`,
    ];
    await Promise.all(cmds.map((cmd) => sh(cmd)));
  },
};
const start: Task = `dune exec bin/Fresh.exe`;
const buildArmImage: Task = {
  fn: async ({ sh }) => {
    const progressArg = "--progress plain";
    const commands = [
      // `docker buildx build ${progressArg} --platform linux/arm/v7 -f Dockerfile.esy-cache -t cdaringe/freshawair:esy-cache  . --load`,
      `docker buildx build ${progressArg} --platform linux/arm/v7 -f Dockerfile -t ${armDockerImageTag}  . --load`,
      // `docker buildx build ${progressArg} --platform linux/arm/v7 -t ${armDockerImageTag}. --load`,
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

export const tasks: Tasks = {
  ...{ s: start, start },
  ...{ f: format, format },
  ...{ opamInstall, opamSetup },
  opam: opamInstall,
  export: opamExport,
  import: opamImport,
  // db crap
  db: {
    fn: async ({ sh }) => {
      await sh(`docker rm -f ${containerName}`).catch(() => {});
      sh(
        [
          `docker run`,
          `--name ${containerName}`,
          // `--user $USER`,
          `-p 5432:5432`,
          `-e POSTGRES_USER=${dbSuperUser}`,
          // `-v $PWD/db.init:/docker-entrypoint-initdb.d`,
          // `-v $PWD/db:/var/lib/postgresql/data`,
          `-e POSTGRES_PASSWORD=${dbSuperPassword}`,
          `timescale/timescaledb:latest-pg12`,
        ].join(" "),
      );
      // giv the db a fightin chance
      await new Promise((res) => setTimeout(res, 2000));
      console.log("\n---\n");
      let tries = 5;
      while (tries) {
        try {
          await sh(`rad -l info db:init`);
          break;
        } catch {
          await new Promise((res) => setTimeout(res, 500));
        }
        --tries;
        if (!tries) throw new Error("bummer, couldn't init the db");
      }
      console.log(`\n\ndb initialized\n\n`);
    },
  },
  "db:init": {
    async fn({ sh }) {
      const pgSuper = await createClient(
        { asSuper: true, database: "postgres" },
      );
      const sqlAddUser = await Deno.readTextFile("002_init_user.sql");
      for (
        const cmd of sqlAddUser.split("\n").map((s) => s.trim()).filter(Boolean)
      ) {
        await pgSuper.query(cmd);
      }
      const sqlAddTable = await Deno.readTextFile("004_init_table.sql");
      const pgStandard = await createClient({});
      await pgStandard.query(sqlAddTable);
    },
  },
  "db:seed": {
    fn: async ({ sh }) => {
      const copyQ = "-c '\\copy sensor_stats from STDIN with(format csv)'";
      await sh(
        `rad db:emitseeddata | docker exec -i ${containerName} psql -U ${dbname} ${dbuser} ${copyQ}`,
      );
    },
  },
  "db:emitseeddata": {
    fn() {
      let i = 525_600; // minutes in a year
      while (i) {
        const vals: any[] = Array.from(Array(14)).map(() => Math.random());
        vals[9] = new Date().toISOString();
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
};
