import { randomUUID } from "crypto";
import { DestinationEntry, SourceEntry } from "./types";

export function canonicalizeArchiveEntry(source: SourceEntry): DestinationEntry {
  return {
    ...source.properties,
    time: new Date(Number(source.properties.time) * 1000).toISOString(),
    _fivetran_id: randomUUID(),
  };
}
