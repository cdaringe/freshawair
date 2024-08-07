import type { Task, Tasks } from "./.rad/common.ts";
import { tasks as dbTasks } from "./.rad/db.ts";
import { deploy } from "./.rad/deploy.ts";
import { format } from "./.rad/format.ts";

const build = `docker build -t cdaringe/freshawair .`;
// const build = `docker buildx build --platform linux/amd64 -t cdaringe/freshawair .`;

const startAgent: Task = [
  "cargo run -p agent --",
  "--awair-endpoint=http://grant.awair/air-data/latest", // local
  "--awair-endpoint=http://malcom.awair/air-data/latest",
  "--db-host=localhost",
  "--db-port=5432",
].join(" ");

const dev = `docker-compose -f docker-compose.dev.yml -f docker-compose.yml up`;

// run `rad --list` to see all tasks
export const tasks: Tasks = {
  ...{ b: build, build },
  ...{ d: dev, dev },
  ...{ startAgent, sa: startAgent },
  ...{ format, f: format },
  ...dbTasks,
  deploy,
};
