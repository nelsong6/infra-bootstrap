// Count documents in both accounts container-by-container to verify the
// migration. Prints SRC vs DST counts side by side; any mismatch is loud.

import { CosmosClient } from "@azure/cosmos";
import { execFileSync } from "node:child_process";

const AZ_OPTS = { encoding: "utf8", shell: true };
const RG = "infra";
const accounts = ["infra-cosmos", "infra-cosmos-serverless"];
const containers = [
  { db: "HomepageDB", c: "userdata" },
  { db: "HomepageDB", c: "fzt-frontend-data" },
  { db: "InvestingDB", c: "portfolios" },
  { db: "WorkoutTrackerDB", c: "workouts" },
  { db: "PlantAgentDB", c: "rooms" },
  { db: "PlantAgentDB", c: "push-subscriptions" },
  { db: "PlantAgentDB", c: "analyses" },
  { db: "PlantAgentDB", c: "events" },
  { db: "PlantAgentDB", c: "plants" },
  { db: "PlantAgentDB", c: "chats" },
  { db: "LightsDB", c: "config" },
];

function primaryKey(account) {
  return execFileSync(
    "az",
    ["cosmosdb", "keys", "list", "--name", account, "-g", RG, "--query", "primaryMasterKey", "-o", "tsv"],
    AZ_OPTS,
  ).trim();
}

async function countDocs(client, db, c) {
  const { resources } = await client
    .database(db)
    .container(c)
    .items.query("SELECT VALUE COUNT(1) FROM c")
    .fetchAll();
  return resources[0] ?? 0;
}

const clients = Object.fromEntries(
  accounts.map((a) => [
    a,
    new CosmosClient({ endpoint: `https://${a}.documents.azure.com:443/`, key: primaryKey(a) }),
  ]),
);

console.log(`${"container".padEnd(42)}  ${"src".padStart(6)}  ${"dst".padStart(6)}  match`);
let allMatch = true;
for (const { db, c } of containers) {
  const src = await countDocs(clients["infra-cosmos"], db, c);
  const dst = await countDocs(clients["infra-cosmos-serverless"], db, c);
  const ok = src === dst;
  if (!ok) allMatch = false;
  console.log(
    `${(db + "/" + c).padEnd(42)}  ${String(src).padStart(6)}  ${String(dst).padStart(6)}  ${ok ? "ok" : "MISMATCH"}`,
  );
}
console.log(allMatch ? "all containers match" : "MISMATCHES PRESENT");
process.exit(allMatch ? 0 : 1);
