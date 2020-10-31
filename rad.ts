import type { Task, Tasks } from "https://deno.land/x/rad@v4.1.1/src/mod.ts";
import addMinutes from "https://deno.land/x/date_fns@v2.15.0/addMinutes/index.js";

const composeDevArgs = "-f docker-compose.yml -f docker-compose.dev.yml";

// db
const containerName = "freshawair_freshdb_1";
const dbname = "fresh";
const dbuser = "fresh";

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
const startServer: Task =
  `opam exec -- dune exec bin/Server.exe -- -auth-token abc`;

export const tasks: Tasks = {
  ...{
    sa:
      `${startAgent} -- -data-store-endpoint http://localhost:8000/air/stats -poll-duration 10 -auth-token abc`,
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
      await sh(`docker-compose ${composeDevArgs} down freshdb -f`).catch(
        () => {},
      );
      await sh(`docker-compose ${composeDevArgs} up freshdb`).catch(() => {});
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
      const now = new Date();
      const degreesToRadians = (deg: number) => (deg / 360) * Math.PI * 2;
      let i = 0; // minutes in a year
      while (i < 525_600) {
        const vals: any[] = Array.from(Array(14)).map(() =>
          Math.sin(degreesToRadians(i))
        );
        // timestamp
        vals[9] = addMinutes(now, i).toISOString();
        console.log(`${vals.join(",")}`);
        ++i;
      }
    },
  },
  psql: {
    fn: async ({ sh }) => {
      await sh(`psql -h 127.0.0.1 -U ${dbname} ${dbuser}`);
    },
  },
};
