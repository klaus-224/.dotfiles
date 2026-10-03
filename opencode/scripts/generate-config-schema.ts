import { writeFileSync } from "node:fs";
import { Config } from "@opencode/schema";
import { Schema } from "effect";

const document = Schema.toJsonSchemaDocument(Config.Info);
const schema = {
  $schema: "https://json-schema.org/draft/2020-12/schema",
  $comment: "Generated from @opencode/schema@2.0.20; run pnpm schema:generate after updating that package.",
  title: "OpenCode 2.0.20 configuration",
  ...document.schema,
  $defs: document.definitions,
};

for (const profile of ["personal", "work"]) {
  writeFileSync(
    new URL(`../${profile}/opencode.schema.json`, import.meta.url),
    `${JSON.stringify(schema, null, 2)}\n`,
  );
}
