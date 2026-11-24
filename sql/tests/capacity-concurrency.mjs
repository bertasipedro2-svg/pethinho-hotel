import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { setTimeout as delay } from "node:timers/promises";
import EmbeddedPostgres from "embedded-postgres";

const dir = await mkdtemp(join(tmpdir(), "pethinho-lab-"));
const server = new EmbeddedPostgres({
  databaseDir: dir, port: Number(process.env.PETHINHO_TEST_PG_PORT ?? 55433),
  password: randomUUID(), postgresFlags: ["-c", "listen_addresses=127.0.0.1", "-c", "unix_socket_directories="],
  onLog: () => {},
});
const clients = [];
let started = false;
try {
  await server.initialise();
  await server.start();
  started = true;
  for (let i = 0; i < 3; i++) {
    const client = server.getPgClient("postgres", "127.0.0.1");
    clients.push(client);
    await client.connect();
    await client.query("set statement_timeout = '10s'");
  }
  const [control, first, second] = clients;
  await control.query(`
    create role anon;
    create role authenticated;
    create schema auth;
    create table auth.users(id uuid primary key);
    create function auth.uid() returns uuid language sql stable as $$
      select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
    create extension btree_gist;
    create function public.create_profile() returns trigger language plpgsql security definer as $$begin return new; end$$;
    create function public.validate_booking_pet() returns trigger language plpgsql as $$begin return new; end$$;
    create function public.enforce_booking_pet_owner() returns trigger language plpgsql as $$begin return new; end$$;
    create table public.pets(id uuid primary key, owner_id uuid not null);
    create table public.staff_roles(user_id uuid primary key, role text);
    create table public.services(id uuid primary key, active boolean not null);
    create table public.accommodations(id uuid primary key, capacity int not null, active boolean not null);
    create table public.bookings(
      id uuid primary key default gen_random_uuid(), owner_id uuid not null, pet_id uuid not null references public.pets,
      service_id uuid not null references public.services, accommodation_id uuid references public.accommodations,
      starts_at timestamptz not null, ends_at timestamptz not null, status text not null,
      notes text, created_at timestamptz not null default now()
    );
    alter table public.bookings add exclude using gist
      (pet_id with =, tstzrange(starts_at,ends_at,'[)') with &&)
      where (status in ('approved','awaiting_payment','confirmed','checked_in'));
  `);
  for (const file of ["./live-function-baseline.sql", "../capacity_and_booking_retry.sql", "../restrict_function_execution.sql", "../admin_finance_ledger.sql"]) {
    await control.query(await readFile(new URL(file, import.meta.url), "utf8"));
  }
  await control.query(`
    create trigger capacity before insert or update of accommodation_id,starts_at,ends_at,status
      on public.bookings for each row execute function public.enforce_accommodation_booking_capacity();
    alter table public.bookings enable row level security;
    create policy booking_read on public.bookings for select to authenticated
      using (owner_id = auth.uid() or public.is_staff());
    grant usage on schema auth to authenticated;
    grant select on public.bookings to authenticated;
    revoke execute on function public.request_booking(uuid,uuid,timestamptz,timestamptz,text) from public, anon;
    grant execute on function public.request_booking(uuid,uuid,timestamptz,timestamptz,text) to authenticated;
  `);
  const owner = randomUUID(), outsider = randomUUID(), employee = randomUUID(), admin = randomUUID();
  const room = randomUUID(), room2 = randomUUID(), service = randomUUID();
  const pets = Array.from({length: 9}, () => randomUUID());
  for (const pet of pets) await control.query("insert into public.pets values ($1,$2)", [pet, owner]);
  await control.query("insert into public.staff_roles values ($1,'staff'),($2,'admin')", [employee,admin]);
  await control.query("insert into public.services values ($1,true)", [service]);
  await control.query("insert into public.accommodations values ($1,2,true),($2,1,true)", [room,room2]);
  const date = (hour) => new Date(Date.UTC(2099, 0, 1, hour)).toISOString();
  const write = (client, pet, accommodation, start, end) => client.query(
    "insert into public.bookings(owner_id,pet_id,service_id,accommodation_id,starts_at,ends_at,status) values($1,$2,$3,$4,$5,$6,'approved')",
    [owner, pet, service, accommodation, date(start), date(end)],
  );
  await write(control, pets[0], room, 1, 3);
  await write(control, pets[1], room, 3, 5);
  await write(control, pets[2], room, 1, 5);
  await assert.rejects(write(control, pets[3], room, 2, 4), {code:"23514"});
  await assert.rejects(write(control, pets[2], room2, 2, 4), {code:"23P01"});

  async function overlap(runFirst, runSecond) {
    await first.query("begin");
    const value = await runFirst(first);
    const pending = runSecond(second).then(result => ({result}), error => ({error}));
    let blocked = false;
    for (let i = 0; i < 75; i++) {
      const {rows} = await control.query("select wait_event_type from pg_stat_activity where pid=$1", [second.processID]);
      if (rows[0]?.wait_event_type === "Lock") { blocked = true; break; }
      await delay(20);
    }
    await first.query("commit");
    assert.equal(blocked, true);
    return [value, await pending];
  }

  const [, conflict] = await overlap(
    client => write(client, pets[4], room2, 8, 10),
    client => write(client, pets[5], room2, 8, 10),
  );
  assert.equal(conflict.error?.code, "23514");
  const request = (client, pet = pets[6]) => client.query(
    "select public.request_booking($1,$2,$3,$4,'fixture') as id", [pet, service, date(12), date(14)],
  );
  for (const client of [first,second]) {
    await client.query("set role authenticated");
    await client.query("select set_config('request.jwt.claim.sub',$1,false)", [owner]);
  }
  const [created, replay] = await overlap(client => request(client), client => request(client));
  assert.equal(replay.result?.rows[0]?.id, created.rows[0].id);
  assert.equal((await control.query("select count(*)::int n from public.bookings where pet_id=$1",[pets[6]])).rows[0].n, 1);
  await second.query("select set_config('request.jwt.claim.sub',$1,false)", [outsider]);
  assert.equal((await second.query("select count(*)::int n from public.bookings")).rows[0].n, 0);
  await assert.rejects(request(second), /Pet not owned/);

  await second.query("reset role");
  await second.query("set role anon");
  await assert.rejects(second.query("select public.is_staff()"), {code:"42501"});
  await assert.rejects(second.query("select public.create_profile()"), {code:"42501"});
  await assert.rejects(request(second), {code:"42501"});
  await second.query("reset role");
  await second.query("set role authenticated");
  for (const [identity, staff, isAdmin] of [[owner,false,false],[employee,true,false],[admin,true,true]]) {
    await second.query("select set_config('request.jwt.claim.sub',$1,false)", [identity]);
    const { rows } = await second.query("select public.is_staff() staff, public.is_admin() admin");
    assert.deepEqual(rows, [{staff,admin:isAdmin}]);
  }
  await assert.rejects(second.query("select public.enforce_accommodation_booking_capacity()"), {code:"42501"});

  const approve = (client) => client.query("select public.approve_booking($1,$2)", [created.rows[0].id,room2]);
  await assert.rejects(approve(first), /Not authorized/);
  await second.query("select set_config('request.jwt.claim.sub',$1,false)", [employee]);
  await approve(second);
  for (const status of ["confirmed", "checked_in", "checked_out", "completed"]) {
    await second.query("select public.transition_booking($1,$2)", [created.rows[0].id,status]);
  }
  assert.equal((await control.query("select status from public.bookings where id=$1",[created.rows[0].id])).rows[0].status,"completed");
  await second.query("select set_config('request.jwt.claim.sub',$1,false)", [admin]);
  console.log("PASS: RPCs operacionais de aprovação, confirmação, check-in, check-out e conclusão.");
  await control.query("insert into auth.users values ($1),($2)", [employee,admin]);
  await first.query("select set_config('request.jwt.claim.sub',$1,false)", [employee]);
  const addEntry = (client) => client.query(
    "insert into public.finance_entries(kind,description,amount_cents,due_on) values ('income','fixture',5300,current_date) returning id,settled_on",
  );
  await assert.rejects(addEntry(first), {code:"42501"});
  const item = (await addEntry(second)).rows[0];
  assert.equal(item.settled_on, null);
  assert.equal((await first.query("select count(*)::int n from public.finance_entries")).rows[0].n, 0);
  await assert.rejects(second.query("update public.finance_entries set amount_cents=1 where id=$1",[item.id]), {code:"42501"});
  const settle = (client) => client.query(
    "update public.finance_entries set settled_on=timezone('America/Sao_Paulo',now())::date where id=$1",[item.id],
  );
  assert.equal((await settle(second)).rowCount,1);
  assert.equal((await settle(second)).rowCount,0);
  console.log("PASS: caixa restrito ao administrador, criação pendente e baixa única sem alterar o valor.");
  await control.query("begin isolation level repeatable read");
  await assert.rejects(write(control, pets[7], room2, 20, 22), {code:"40001"});
  await control.query("rollback");
  console.log("PASS: pico, adjacência, excesso, exclusão por pet, corrida de vagas, retry concorrente, isolamento do tutor e proteção de snapshot.");
} finally {
  await Promise.allSettled(clients.map(client => client.end()));
  if (started) await server.stop();
  await rm(dir,{recursive:true,force:true});
}
