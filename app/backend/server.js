import express from "express";
import { CognitoJwtVerifier } from "aws-jwt-verify";
import { query } from "./db.js";
import { filesRouter } from "./files.js";

const app = express();

app.disable("x-powered-by");

const verifier =
  process.env.COGNITO_USER_POOL_ID && process.env.COGNITO_CLIENT_ID
    ? CognitoJwtVerifier.create({
        userPoolId: process.env.COGNITO_USER_POOL_ID,
        tokenUse: "access",
        clientId: process.env.COGNITO_CLIENT_ID,
      })
    : null;

// Пишемо технічні події, без токенів і вмісту нотаток.
app.use((req, res, next) => {
  const started = Date.now();

  res.on("finish", () => {
    if (req.path === "/healthz") return;

    console.log(
      JSON.stringify({
        event: "http_request",
        method: req.method,
        status: res.statusCode,
        duration_ms: Date.now() - started,
      }),
    );
  });

  next();
});

app.get("/healthz", (req, res) => {
  res.json({ status: "ok" });
});

// Відповіді API не повинні кешуватися браузером.
app.use("/api", (req, res, next) => {
  res.set("Cache-Control", "no-store");
  next();
});

app.use("/api", async (req, res, next) => {
  if (!verifier) {
    return res.status(503).json({
      error: "Authentication is not configured",
    });
  }

  const authorization = req.get("authorization") || "";
  const match = authorization.match(/^Bearer (\S+)$/i);

  if (!match) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  try {
    const payload = await verifier.verify(match[1]);
    req.ownerSub = payload.sub;
    next();
  } catch {
    return res.status(401).json({ error: "Unauthorized" });
  }
});

app.use(express.json({ limit: "16kb" }));
app.use("/api/files", filesRouter);

app.get("/api/notes", async (req, res, next) => {
  try {
    const result = await query(
      `SELECT id, content, created_at
       FROM app.notes
       WHERE owner_sub = $1
       ORDER BY id DESC
       LIMIT 100`,
      [req.ownerSub],
    );

    res.json({ notes: result.rows });
  } catch (error) {
    next(error);
  }
});

app.post("/api/notes", async (req, res, next) => {
  if (!req.is("application/json")) {
    return res.status(415).json({
      error: "Content-Type must be application/json",
    });
  }

  const content = req.body?.content;

  if (
    typeof content !== "string" ||
    content.trim().length === 0 ||
    content.length > 2000
  ) {
    return res.status(400).json({
      error: "Content must contain 1 to 2000 characters",
    });
  }

  try {
    const result = await query(
      `INSERT INTO app.notes (owner_sub, content)
       VALUES ($1, $2)
       RETURNING id, content, created_at`,
      [req.ownerSub, content.trim()],
    );

    res.status(201).json({ note: result.rows[0] });
  } catch (error) {
    next(error);
  }
});

app.use((req, res) => {
  res.status(404).json({ error: "Not found" });
});

app.use((error, req, res, next) => {
  if (error.type === "entity.too.large") {
    return res.status(413).json({ error: "Request body is too large" });
  }

  if (error.type === "entity.parse.failed") {
    return res.status(400).json({ error: "Invalid JSON" });
  }

  console.error(
    JSON.stringify({
      event: "request_failed",
      code: error.code || error.name || "unknown",
    }),
  );

  res.status(503).json({ error: "Service temporarily unavailable" });
});

const server = app.listen(3000, "127.0.0.1", () => {
  console.log(
    JSON.stringify({
      event: "server_started",
      port: 3000,
    }),
  );
});

server.requestTimeout = 30000;
server.headersTimeout = 15000;
