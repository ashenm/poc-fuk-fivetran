import { GetObjectCommandOutput, S3 } from "@aws-sdk/client-s3";
import { WriteStream, createReadStream, createWriteStream, readFileSync } from "fs";
import { Interface, createInterface } from "readline";
import { Readable, Writable } from "stream";
import { pipeline } from "stream/promises";
import { addEOL, archiveLineTransformer } from "./transformers";
import { createGzip } from "zlib";
import Logger from "@ashenm/logger";

const DESTINATION_ARCHIVE_FILENAME: string = "/tmp/destination.json.gz";
const SOURCE_ARCHIVE_FILENAME: string = "/tmp/source.json";

const client: S3 = new S3();

export async function getEventArchive(bucket: string, key: string): Promise<void> {
  Logger.getInstance().info({ message: "Attempting source archive retrieval" });
  const response: GetObjectCommandOutput = await client.getObject({ Bucket: bucket, Key: key });
  const source: ReadableStream = response.Body.transformToWebStream();
  const archive: WriteStream = createWriteStream(SOURCE_ARCHIVE_FILENAME);
  await source.pipeThrough(new DecompressionStream("gzip")).pipeTo(Writable.toWeb(archive));
}

export async function createStagingArchive(): Promise<void> {
  Logger.getInstance().info({ message: "Attempting staging archive creation" });
  const source: Readable = createReadStream(SOURCE_ARCHIVE_FILENAME);
  const sourceInterface: Interface = createInterface(source);
  const destination: Writable = createWriteStream(DESTINATION_ARCHIVE_FILENAME);
  archiveLineTransformer.setMaxListeners(0);
  addEOL.setMaxListeners(0);
  await pipeline(sourceInterface, archiveLineTransformer, addEOL, createGzip(), destination);
}

export async function saveStagingArchive(bucket: string, key: string): Promise<void> {
  const [_prefix, ...rest]: string[] = key.split("/");
  const destinationKey: string = ["stagings", ...rest].join("/");

  Logger.getInstance().info({
    message: "Attempting staging archive saving",
    context: { bucket, key: destinationKey },
  });

  await client.putObject({
    Bucket: bucket,
    Key: destinationKey,
    Body: readFileSync(DESTINATION_ARCHIVE_FILENAME),
    ContentEncoding: "gzip",
  });
}
