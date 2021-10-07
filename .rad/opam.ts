import type { Task, Tasks } from "./common.ts";

const opamSetup: Task = {
  async fn({ logger, sh }) {
    try {
      await sh(`opam switch 4.12.0+domains`);
    } catch (err) {
      logger.error(err);
      throw new Error(
        "need to https://github.com/ocaml-multicore/multicore-opam#install-multicore-ocaml?",
      );
    }
  },
};
const opamInstall: Task = {
  dependsOn: [opamSetup],
  fn: async ({ sh }) => sh(`bash ./opam.dev.deps.sh`),
};
const opamExport: Task = `opam switch export freshawair.opam.deps`;
const opamImport: Task = `opam switch import freshawair.opam.deps`;

export const tasks: Tasks = {
  opamSetup,
  opamInstall,
  opamExport,
  opamImport,
};
