import { Router } from "express";
import {
  S3Client,
  PutObjectCommand,
  ListObjectsV2Command,
  GetObjectCommand,
} from "@aws-sdk/client-s3";

export const filesRouter = Router();

const s3 = new S3Client({
  region: process.env.AWS_REGION || "eu-central-1",
});

const bucket = process.env.CLIENT_FILES_BUCKET;
const maxSize = 4096;

function validName(name) {
  return (
    typeof name === "string" &&
    /^[\p{L}\p{N} ._-]{1,100}$/u.test(name) &&
    name !== "." &&
    name !== ".."
  );
}

filesRouter.get("/", async (req, res, next) => {
  try {
    const prefix = `users/${req.ownerSub}/`;

    const result = await s3.send(
      new ListObjectsV2Command({
        Bucket: bucket,
        Prefix: prefix,
        MaxKeys: 100,
      }),
    );

    res.json({
      files: (result.Contents || []).map((object) => ({
        name: object.Key.slice(prefix.length),
        size: object.Size,
      })),
    });
  } catch (error) {
    next(error);
  }
});

filesRouter.post("/", async (req, res, next) => {
  const { name, base64 } = req.body || {};

  if (!validName(name) || typeof base64 !== "string") {
    return res.status(400).json({ error: "Invalid filename or content" });
  }

  const body = Buffer.from(base64, "base64");

  if (body.length > maxSize) {
    return res.status(413).json({ error: "Maximum file size is 4 KiB" });
  }

  try {
    await s3.send(
      new PutObjectCommand({
        Bucket: bucket,
        Key: `users/${req.ownerSub}/${name}`,
        Body: body,
        ContentType: "application/octet-stream",
      }),
    );

    res.status(201).json({ name });
  } catch (error) {
    next(error);
  }
});

filesRouter.get("/download", async (req, res, next) => {
  const name = req.query.name;

  if (!validName(name)) {
    return res.status(400).json({ error: "Invalid filename" });
  }

  try {
    const result = await s3.send(
      new GetObjectCommand({
        Bucket: bucket,
        Key: `users/${req.ownerSub}/${name}`,
      }),
    );

    if (result.ContentLength > maxSize) {
      result.Body.destroy();
      return res.status(413).json({ error: "File exceeds the lab limit" });
    }

    res.json({
      name,
      base64: await result.Body.transformToString("base64"),
    });
  } catch (error) {
    if (error.name === "NoSuchKey") {
      return res.status(404).json({ error: "File not found" });
    }

    next(error);
  }
});
