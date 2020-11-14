import type { Task, Tasks } from "./.rad/common.ts";
import { tasks as dbTasks } from "./.rad/db.ts";
import { tasks as opamTasks } from "./.rad/opam.ts";
import { tasks as uiTasks } from "./.rad/ui.ts";
import { deploy } from "./.rad/deploy.ts";
import { format } from "./.rad/format.ts";

const duneExec = "opam exec -- dune exec";

const startAgent: Task =
  `${duneExec} bin/Agent.exe -- -data-store-endpoint http://localhost:8000/air/stats -poll-duration 10 -auth-token abc`;
const startServer: Task = `${duneExec} bin/Server.exe -- -auth-token abc`;

// run `rad --list` to see all tasks
export const tasks: Tasks = {
  ...{ startAgent, sa: startAgent },
  ...{ startServer, ss: startServer },
  ...{ format, f: format },
  ...opamTasks,
  ...dbTasks,
  ...uiTasks,
  deploy,
};
