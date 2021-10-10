import type { Task, Tasks } from "./.rad/common.ts";
import { tasks as dbTasks } from "./.rad/db.ts";
import { tasks as opamTasks } from "./.rad/opam.ts";
import { deploy } from "./.rad/deploy.ts";
import { format } from "./.rad/format.ts";

const build = `dune build`;
const duneExec = "opam exec -- dune exec";

const startAgent: Task = `${duneExec} bin/Agent.exe -- --poll-duration 10`;

// run `rad --list` to see all tasks
export const tasks: Tasks = {
  ...{ b: build, build },
  ...{ startAgent, sa: startAgent },
  ...{ format, f: format },
  ...opamTasks,
  ...dbTasks,
  deploy,
};
