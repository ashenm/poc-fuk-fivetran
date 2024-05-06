import Logger from "@ashenm/logger";
import { S3Event, S3EventRecord, SQSEvent, SQSHandler, SQSRecord } from "aws-lambda";
import { getSchemaTable } from "./utilities";
import { copyArchive } from "./redshift";
import config from "../config";

export const handler: SQSHandler = async function (event: SQSEvent): Promise<void> {
  const logger: Logger = new Logger({ environment: config.ENVIRONMENT });
  try {
    logger.info({
      message: "Incoming archive copying event",
      context: event,
    });

    const [record]: SQSRecord[] = event.Records;
    const message: S3Event = JSON.parse(record.body);

    if (!message.Records) {
      logger.warn({ message: "Ignoring malformed canonicalization event", context: message });
      return;
    }

    const [notification]: S3EventRecord[] = message.Records;
    const key: string = notification.s3.object.key;
    const filename: string = `s3://${notification.s3.bucket.name}/${key}`;
    const table: string = getSchemaTable(key);
    await copyArchive(table, filename);
  } catch (exception) {
    logger.error({
      message: "Failed to process archive copying",
      context: exception,
    });
  }
};
