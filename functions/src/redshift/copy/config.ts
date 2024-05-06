const config: {
  ENVIRONMENT: string;
  REDSHIFT_CLUSTER_IDENTIFIER: string;
  REDSHIFT_DATABASE: string;
  REDSHIFT_DATABASE_USER: string;
  REDSHIFT_SERVICE_ROLE_ARN: string;
} = Object.assign(Object.create(null), process.env);

export default config;
