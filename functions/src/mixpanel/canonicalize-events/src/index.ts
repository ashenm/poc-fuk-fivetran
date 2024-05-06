import Logger from "@ashenm/logger";
import { S3Event, S3EventRecord, SQSEvent, SQSHandler, SQSRecord } from "aws-lambda";
import { createStagingArchive, getEventArchive, saveStagingArchive } from "./archive";
import config from "../config";

export const handler: SQSHandler = async function (event: SQSEvent): Promise<void> {
  const logger: Logger = new Logger({
    environment: config.ENVIRONMENT,
  });

  try {
    logger.info({
      message: "Incoming Mixpanel canonicalization event",
      context: event,
    });

    const [record]: SQSRecord[] = event.Records;
    const message: S3Event = JSON.parse(record.body);

    if (!message.Records) {
      logger.warn({ message: "Ignoring malformed canonicalization event", context: message });
      return;
    }

    const [notification]: S3EventRecord[] = message.Records;

    const bucket: string = notification.s3.bucket.name;
    const key: string = notification.s3.object.key;

    logger.info({
      message: "Attempting Mixpanel archive processing",
      context: { bucket, key },
    });

    await getEventArchive(bucket, key);
    await createStagingArchive();
    await saveStagingArchive(bucket, key);
  } catch (exception) {
    logger.error({
      message: "Failed to process Mixpanel archive",
      context: exception,
    });
  }
};
