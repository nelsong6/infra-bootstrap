// Copy every container from infra-cosmos (old, provisioned) to
// infra-cosmos-serverless (new). Auth via primary keys pulled from
// `az cosmosdb keys list` — requires `az login` in the shell.
//
// One-shot tool: safe to rerun (upserts, creates DBs/containers if missing).
// Delete this directory once the App Config flip is verified and the old
// account has been torn out.

import { CosmosClient } from "@azure/cosmos";
import { execFileSync } from "node:child_process";

// `.cmd` shim under Windows requires shell resolution.
const AZ_OPTS = { encoding: "utf8", shell: true };

const RG = "infra";
const SRC_ACCOUNT = "infra-cosmos";
const DST_ACCOUNT = "infra-cosmos-serverless";

// Every container currently on infra-cosmos. Partition keys verified via
// `az cosmosdb sql container show`. BenderWorldDB was already deleted.
const containers = [
  { db: "HomepageDB", c: "userdata", pk: "/userId" },
  { db: "HomepageDB", c: "fzt-frontend-data", pk: "/userId" },
  { db: "InvestingDB", c: "portfolios", pk: "/userId" },
  { db: "WorkoutTrackerDB", c: "workouts", pk: "/userId" },
  { db: "PlantAgentDB", c: "rooms", pk: "/id" },
  { db: "PlantAgentDB", c: "push-subscriptions", pk: "/userId" },
  { db: "PlantAgentDB", c: "analyses", pk: "/plantId" },
  { db: "PlantAgentDB", c: "events", pk: "/plantId" },
  { db: "PlantAgentDB", c: "plants", pk: "/id" },
  { db: "PlantAgentDB", c: "chats", pk: "/plantId" },
  { db: "LightsDB", c: "config", pk: "/userId" },
];

// System properties injected by Cosmos on every document; strip before write
// so the destination issues its own.
const SYSTEM_FIELDS = ["_rid", "_self", "_etag", "_ts", "_attachments"];

function primaryKey(account) {
  const out = execFileSync(
    "az",
    ["cosmosdb", "keys", "list", "--name", account, "-g", RG, "--query", "primaryMasterKey", "-o", "tsv"],
    AZ_OPTS,
  );
  return out.trim();
}

function endpoint(account) {
  return `https://${account}.documents.azure.com:443/`;
}

async function migrateOne(src, dst, { db, c, pk }) {
  await dst.databases.createIfNotExists({ id: db });
  await dst.database(db).containers.createIfNotExists({
    id: c,
    partitionKey: { paths: [pk] },
  });

  const srcContainer = src.database(db).container(c);
  const dstContainer = dst.database(db).container(c);

  let copied = 0;
  let skipped = 0;
  const iterator = srcContainer.items.readAll({ maxItemCount: 100 }).getAsyncIterator();
  for await (const page of iterator) {
    for (const doc of page.resources) {
      const clean = { ...doc };
      for (const k of SYSTEM_FIELDS) delete clean[k];
      try {
        await dstContainer.items.upsert(clean);
        copied++;
      } catch (err) {
        console.error(`  ! ${db}/${c} doc id=${doc.id}: ${err.code ?? err.message}`);
        skipped++;
      }
    }
  }
  console.log(`  ${db}/${c}: ${copied} copied${skipped ? `, ${skipped} skipped` : ""}`);
}

async function main() {
  console.log(`src: ${SRC_ACCOUNT}  →  dst: ${DST_ACCOUNT}`);
  const src = new CosmosClient({ endpoint: endpoint(SRC_ACCOUNT), key: primaryKey(SRC_ACCOUNT) });
  const dst = new CosmosClient({ endpoint: endpoint(DST_ACCOUNT), key: primaryKey(DST_ACCOUNT) });

  for (const spec of containers) {
    await migrateOne(src, dst, spec);
  }
  console.log("done");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
