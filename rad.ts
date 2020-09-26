import type {
  Task,
  Tasks,
} from "https://deno.land/x/rad@v4.1.1/src/mod.ts";
import { Client } from "https://deno.land/x/postgres@v0.4.5/mod.ts";

const dbname = "freshawairdb";
const dbuser = "postgres";
const scripts = JSON.parse(Deno.readTextFileSync("./package.json")).scripts;

const format: Task = {
  fn: ({ sh }) => sh(`deno fmt rad.ts && ${scripts.format}`),
};
const start: Task = `esy x refmterr dune exec bin/Fresh.exe`
export const tasks: Tasks = {
  ...{ s: start, start} ,
  ...Object.keys(scripts).reduce(
    (acc, name) => ({ ...acc, [name]: scripts[name] }),
    {},
  ),
  ...{ f: format, format },
  db: {
    fn: async ({ sh }) => {
      await sh(`docker rm -f ${dbname}`).catch(() => {});
      sh(
        `docker run -d --name ${dbname} -p 5432:5432 -e POSTGRES_USER=${dbuser} -v $PWD/db:/var/lib/postgresql/data -e POSTGRES_PASSWORD=${dbuser} timescale/timescaledb:latest-pg12`,
      );
    },
  },
  "db:seed": {
    fn: async ({ sh, logger }) => {
      const pg = new Client({
        user: `${dbuser}`,
        hostname: `127.0.0.1`,
        database: `${dbuser}`,
        password: `${dbuser}`,
        port: 5432,
      });
      await pg.connect();
      await pg.query(`create table sensor_stats(
        abs_humid float,
        co2 float,
        co2_est float,
        dew_point float,
        humid float,
        pm10_est float,
        pm25 float,
        score float,
        temp float,
        timestamp timestamp,
        voc float,
        voc_baseline float,
        voc_ethanol_raw float,
        voc_h2_raw float
      );`).catch((err) => {
        if (err && err.message.match(/already exists/)) return;
        throw err;
      });
      const copyQ = "-c '\\copy sensor_stats from STDIN with(format csv)'";
      await sh(
        `rad db:emitseeddata | docker exec -i ${dbname} psql -U ${dbuser} ${copyQ}`,
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
      await sh("psql -h 127.0.0.1 -U postgres");
    },
  },
  wait: {
    fn: async () => {
      return 1;
    },
  },
};
