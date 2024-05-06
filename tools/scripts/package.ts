import archiver from "archiver";
import { WriteStream, createWriteStream } from "fs";
import path from "path";
import { Arguments } from "yargs";
import yargs from "yargs/yargs";
import { Options } from "./types";

(async function main() {
  const argv: Arguments<Partial<Options>> = await yargs(process.argv).argv;

  if (!argv.source) {
    return;
  }

  const source: string = path.join("dist", argv.source);
  const destination: string = path.join("dist", `${argv.source}.zip`);

  const output: WriteStream = createWriteStream(destination);
  const archive: archiver.Archiver = archiver("zip", {});

  archive.pipe(output);
  archive.glob("*", { cwd: source }, { mode: 0o644 });
  archive.finalize();
})();
