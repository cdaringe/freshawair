import type { Task, Tasks } from "./common.ts";

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

export const tasks: Tasks = {
  opamSetup,
  opamInstall,
  opamExport,
  opamImport,
};
