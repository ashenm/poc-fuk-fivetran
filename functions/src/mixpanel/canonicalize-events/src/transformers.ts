import { Transform, TransformCallback } from "stream";
import { canonicalizeArchiveEntry } from "./mappers";
import { DestinationEntry, SourceEntry } from "./types";

const EOL: Buffer = Buffer.from("\n");

export const archiveLineTransformer: Transform = new Transform({
  transform(chunk: Buffer, _encoding: string, callback: TransformCallback): void {
    try {
      const source: SourceEntry = JSON.parse(chunk.toString());
      const entry: DestinationEntry = canonicalizeArchiveEntry(source);
      callback(null, Buffer.from(JSON.stringify(entry)));
    } catch (exception) {
      callback(exception);
    }
  },
});

export const addEOL: Transform = new Transform({
  transform(chunk: Buffer, _encoding: string, callback: TransformCallback): void {
    try {
      callback(null, Buffer.concat([chunk, EOL]));
    } catch (exception) {
      callback(exception);
    }
  },
});
