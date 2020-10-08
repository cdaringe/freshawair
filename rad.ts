import type {
  Task,
  Tasks,
} from "https://deno.land/x/rad@v4.1.1/src/mod.ts";
import { Client } from "https://deno.land/x/postgres@v0.4.5/mod.ts";
import type { ConnectionOptions } from "https://deno.land/x/postgres@v0.4.5/connection_params.ts";

const containerName = "freshawairdb";
const dbname = "fresh";
const dbuser = "fresh";
const dbSuperUser = "postgres";
const dbSuperPassword = dbSuperUser;
const scripts = JSON.parse(Deno.readTextFileSync("./package.json")).scripts;

const createClient = async (
  { asSuper, ...rest }: { asSuper?: boolean } & Partial<ConnectionOptions>,
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

const armImageName = "armocaml";

const dbi = `docker build -t ${armImageName} .`;

const format: Task = {
  fn: ({ sh }) => sh(`deno fmt rad.ts && ${scripts.format}`),
};
const start: Task = `esy x dune exec bin/Fresh.exe`;
export const tasks: Tasks = {
  ...Object.keys(scripts).reduce(
    (acc, name) => ({ ...acc, [name]: scripts[name] }),
    {},
  ),
  ...{ f: format, format },
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
          await sh(`rad db:init`);
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
  wait: {
    fn: async () => {
      return 1;
    },
  },
  ...{ dbi, "docker:build:image": dbi },
  "arm:shell":
    "docker run -it --rm --entrypoint /bin/bash ocaml/opam2-staging:debian-10-ocaml-4.06-linux-arm32v7",
  "build:arm": {
    async fn({ sh }) {
      await sh(
        `docker buildx build --progress plain --platform linux/arm/v7 -f Dockerfile.esy-cache -t cdaringe/freshawair:esy-cache  . --load`,
      );
      await sh(
        `docker buildx build --progress plain --platform linux/arm/v7 -t cdaringe/freshawair:arm . --load`,
      );
    },
  },
  ...{ s: start, start },
};
