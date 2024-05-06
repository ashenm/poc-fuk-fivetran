import Logger from "@ashenm/logger";
import config from "../config";
import { sleep } from "@poc-fuk-fivetran/lib";
import {
  DescribeStatementResponse,
  ExecuteStatementInput,
  ExecuteStatementOutput,
  RedshiftData,
  StatusString,
} from "@aws-sdk/client-redshift-data";

const MAX_EXECUTION_RETRY_ATTEMPTS: number = 10;

export async function copyArchive(table: string, filename: string): Promise<void> {
  let executionStatusCheckAttempt: number = 0;

  const client: RedshiftData = new RedshiftData();
  const logger: Logger = Logger.getInstance();

  const serviceIamRoleArn: string = config.REDSHIFT_SERVICE_ROLE_ARN;

  const statement: ExecuteStatementInput = {
    ClusterIdentifier: config.REDSHIFT_CLUSTER_IDENTIFIER,
    Database: config.REDSHIFT_DATABASE,
    Sql: `COPY ${table} FROM '${filename}' IAM_ROLE '${serviceIamRoleArn}' FORMAT AS JSON 'auto' TIMEFORMAT 'auto' GZIP`,
    DbUser: config.REDSHIFT_DATABASE_USER,
  };

  const output: ExecuteStatementOutput = await client.executeStatement(statement);
  const statementExecutionId: string = output.Id;

  while (true) {
    if (executionStatusCheckAttempt >= MAX_EXECUTION_RETRY_ATTEMPTS) {
      logger.error({
        message: "Archive copy execution timeout",
        context: statementExecutionId,
      });
      break;
    }

    const result: DescribeStatementResponse = await client.describeStatement({ Id: statementExecutionId });

    if (result.Status === StatusString.FINISHED) {
      logger.info({
        message: "Archive copy execution successful",
        context: result,
      });
      break;
    }

    if (result.Status === StatusString.ABORTED || result.Status === StatusString.FAILED) {
      logger.error({
        message: "Archive copy execution unsuccessful",
        context: result,
      });
      break;
    }

    const backoff: number = 2.5 * executionStatusCheckAttempt + 1;

    logger.info({
      message: "Archive copy execution in interim state; retrying with backoff",
      context: { backoff, executionStatusCheckAttempt, result },
    });

    await sleep(backoff);
    executionStatusCheckAttempt++;
  }
}
