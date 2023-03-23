import type { Task, Tasks } from "./.rad/common.ts";
import { tasks as dbTasks } from "./.rad/db.ts";
import { deploy } from "./.rad/deploy.ts";
import { format } from "./.rad/format.ts";

const build = `dune build`;

const startAgent: Task = [
  "cargo run -p agent --",
  "--awair-endpoint=http://192.168.3.2/air-data/latest", // grant
  "--awair-endpoint=http://192.168.3.3/air-data/latest", // malcom
  "--db-host=localhost",
  "--db-port=5432",
].join(" ");

// run `rad --list` to see all tasks
export const tasks: Tasks = {
  ...{ b: build, build },
  ...{ startAgent, sa: startAgent },
  ...{ format, f: format },
  ...dbTasks,
  deploy,
};
