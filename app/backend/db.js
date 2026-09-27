import { readFileSync } from "node:fs";
import pg from "pg";
import {
  SecretsManagerClient,
  GetSecretValueCommand,
} from "@aws-sdk/client-secrets-manager";

const secrets = new SecretsManagerClient({
  region: process.env.AWS_REGION || "eu-central-1",
});

let poolPromise;

async function createPool() {
  const result = await secrets.send(
    new GetSecretValueCommand({
      SecretId: process.env.APP_DB_SECRET_ARN,
    }),
  );

  const credentials = JSON.parse(result.SecretString);

  const pool = new pg.Pool({
    host: process.env.DB_HOST,
    port: 5432,
    database: "appdb",
    user: credentials.username,
    password: credentials.password,

    ssl: {
      ca: readFileSync(process.env.RDS_CA_PATH, "utf8"),
      rejectUnauthorized: true,
    },

    max: 5,
    connectionTimeoutMillis: 5000,
    idleTimeoutMillis: 30000,
    statement_timeout: 5000,
  });

  pool.on("error", (error) => {
    console.error(
      JSON.stringify({
        event: "database_connection_error",
        code: error.code || "unknown",
      }),
    );
  });

  try {
    await pool.query("SELECT 1");
    return pool;
  } catch (error) {
    await pool.end();
    throw error;
  }
}

export async function query(text, values) {
  if (!poolPromise) {
    poolPromise = createPool().catch((error) => {
      poolPromise = undefined;
      throw error;
    });
  }

  const pool = await poolPromise;
  return pool.query(text, values);
}
