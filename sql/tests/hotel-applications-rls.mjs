import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import EmbeddedPostgres from "embedded-postgres";

const dir = await mkdtemp(join(tmpdir(), "pethinho-empresas-"));
const server = new EmbeddedPostgres({
  databaseDir: dir,
  port: Number(process.env.PETHINHO_TEST_PG_PORT ?? 55434),
  password: randomUUID(),
  postgresFlags: ["-c", "listen_addresses=127.0.0.1", "-c", "unix_socket_directories="],
  onLog: () => {},
});
let client;
let started = false;
try {
  await server.initialise();
  await server.start();
  started = true;
  client = server.getPgClient("postgres", "127.0.0.1");
  await client.connect();
  const owner = randomUUID();
  const other = randomUUID();
  const admin = randomUUID();
  const operator = randomUUID();
  await client.query(`
    CREATE ROLE anon;
    CREATE ROLE authenticated;
    CREATE SCHEMA auth;
    CREATE TABLE auth.users (id uuid PRIMARY KEY);
    CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS
      $$ SELECT nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
    CREATE TABLE public.staff_roles (user_id uuid PRIMARY KEY, role text);
    CREATE FUNCTION public.is_admin() RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=''
      AS $$ SELECT EXISTS (SELECT 1 FROM public.staff_roles WHERE user_id = auth.uid() AND role = 'admin') $$;
    GRANT USAGE ON SCHEMA auth TO authenticated;
  `);
  await client.query("INSERT INTO auth.users (id) SELECT unnest($1::uuid[])", [[owner, other, admin, operator]]);
  await client.query("INSERT INTO public.staff_roles VALUES ($1, 'admin'), ($2, 'staff')", [admin, operator]);
  const migration = await readFile(new URL("../hotel_applications.sql", import.meta.url), "utf8");
  await client.query(migration);
  const table = "public.hotel_applications";
  const insert = `INSERT INTO ${table} (business_name,contact_name,city,state,activity,phone) VALUES ('Hotel Teste', 'Contato Teste', 'Itu', 'SP', 'hotel', $1) RETURNING applicant_id, status`;
  const claims = (id) => client.query("SELECT set_config('request.jwt.claim.sub', $1, false)", [id]);

  await client.query("SET ROLE anon");
  await assert.rejects(client.query(`SELECT * FROM ${table}`), { code: "42501" });
  await assert.rejects(client.query(insert, ["11900000000"]), { code: "42501" });
  await client.query("SET ROLE authenticated");
  await claims(owner);
  await assert.rejects(client.query(insert, ["123"]), { code: "23514" });
  await assert.rejects(client.query(`INSERT INTO ${table} (applicant_id, status) VALUES ($1, 'accepted')`, [other]), { code: "42501" });
  const application = await client.query(insert, ["11900000000"]);
  assert.deepEqual(application.rows, [{ applicant_id: owner, status: "pending" }]);
  await assert.rejects(client.query(insert, ["11900000000"]), { code: "23505" });
  assert.equal((await client.query(`UPDATE ${table} SET status = 'accepted'`)).rowCount, 0);
  await claims(other);
  const second = await client.query(insert, ["11911111111"]);
  assert.deepEqual(second.rows, [{ applicant_id: other, status: "pending" }]);
  assert.deepEqual((await client.query(`SELECT applicant_id FROM ${table}`)).rows, [{ applicant_id: other }]);
  await claims(operator);
  assert.equal((await client.query(`SELECT * FROM ${table}`)).rowCount, 0);
  assert.equal((await client.query(`UPDATE ${table} SET status = 'accepted'`)).rowCount, 0);
  await claims(admin);
  assert.equal((await client.query(`SELECT * FROM ${table}`)).rowCount, 2);
  assert.equal((await client.query(`UPDATE ${table} SET status='accepted' WHERE applicant_id=$1`, [owner])).rowCount, 1);
  assert.equal((await client.query(`UPDATE ${table} SET status='declined' WHERE applicant_id=$1`, [owner])).rowCount, 0);
  assert.equal((await client.query(`UPDATE ${table} SET status='declined' WHERE applicant_id=$1`, [other])).rowCount, 1);
  await assert.rejects(client.query(`UPDATE ${table} SET phone='11900000001'`), { code: "42501" });
  await claims(owner);
  assert.deepEqual((await client.query(`SELECT status FROM ${table}`)).rows, [{ status: "accepted" }]);
  await client.query("RESET ROLE");
  assert.equal((await client.query("SELECT count(*)::int AS count FROM public.staff_roles")).rows[0].count, 2);
  const rollback = await readFile(new URL("../rollback/hotel_applications.sql", import.meta.url), "utf8");
  await client.query(rollback);
  assert.equal((await client.query(`SELECT count(*)::int AS count FROM ${table}`)).rows[0].count, 2);
  await client.query("SET ROLE authenticated");
  await assert.rejects(client.query(`SELECT status FROM ${table}`), { code: "42501" });
  console.log("PASS: cadastro, duplicidade, isolamento, análise restrita e reversão sem perda de dados.");
} finally {
  await client?.end();
  if (started) await server.stop();
  await rm(dir, { recursive: true, force: true });
}
