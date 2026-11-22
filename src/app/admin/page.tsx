"use client";
import {useEffect,useMemo,useState} from "react";
import {getSupabase} from "@/lib/supabase";

type Booking={id:string;starts_at:string;ends_at:string;status:string};
const fmt=(date:string)=>new Date(date).toLocaleString("pt-BR",{dateStyle:"short",timeStyle:"short"});
const labels:Record<string,string>={pending:"Pendente",approved:"Aprovada",confirmed:"Confirmada",checked_in:"Hospedado",checked_out:"Check-out",completed:"Concluída",cancelled:"Cancelada",no_show:"Não compareceu"};
export default function Admin(){
 const[allowed,setAllowed]=useState(false),[rows,setRows]=useState<Booking[]>([]);
 const[loading,setLoading]=useState(true),[msg,setMsg]=useState("Verificando permissões...");
 useEffect(()=>{
  let active=true;
  async function load(){
   try{
    const db=getSupabase();
    const{data:{user},error:authError}=await db.auth.getUser();
    if(authError)throw authError;
    if(!user){if(active)setMsg("Faça login para acessar o painel.");return}
    const{data:role,error:roleError}=await db.from("staff_roles").select("role").eq("user_id",user.id).maybeSingle();
    if(roleError)throw roleError;
    if(!role){if(active)setMsg("Acesso restrito à equipe autorizada.");return}
    const{data,error}=await db.from("bookings").select("id,starts_at,ends_at,status").order("starts_at",{ascending:false}).limit(200);
    if(error)throw error;
    if(active){setAllowed(true);setRows(data||[]);setMsg("");}
   }catch(e){if(active){setAllowed(false);setMsg(e instanceof Error?e.message:"Falha ao consultar reservas.");}}
   finally{if(active)setLoading(false)}
  }
  void load();
  return()=>{active=false};
 },[]);
 const stats=useMemo(()=>{
  const counts:Record<string,number>={};
  for(const row of rows)counts[row.status]=(counts[row.status]||0)+1;
  const now=Date.now();
  const upcoming=rows.filter(x=>["approved","confirmed"].includes(x.status)&&new Date(x.starts_at).getTime()>=now&&new Date(x.starts_at).getTime()<now+7*86400000).sort((a,b)=>a.starts_at.localeCompare(b.starts_at));
  const staying=rows.filter(x=>x.status==="checked_in");
  return {counts,upcoming,staying};
 },[rows]);
 return <main>
  <h1>Painel administrativo</h1>
  {loading?<p role="status">Carregando dados e permissões...</p>:
  !allowed?<p role="alert">{msg}</p>:
  <>
   <p role="status">Visão de até 200 reservas recentes. Dados sujeitos às permissões do Supabase; não é um relatório financeiro.</p>
   <section className="card" aria-labelledby="summary"><h2 id="summary">Resumo por situação</h2>
    <ul>{Object.entries(labels).map(([key,label])=><li key={key}>{label}: {stats.counts[key]||0}</li>)}</ul>
   </section>
   <section className="card" aria-labelledby="staying"><h2 id="staying">Hospedagens em andamento ({stats.staying.length})</h2>
    {stats.staying.length===0?<p>Nenhum check-in em andamento nesta consulta.</p>:<ul>{stats.staying.map(x=><li key={x.id}>Entrada {fmt(x.starts_at)} — saída prevista {fmt(x.ends_at)}</li>)}</ul>}
   </section>
   <section className="card" aria-labelledby="upcoming"><h2 id="upcoming">Próximas entradas — 7 dias ({stats.upcoming.length})</h2>
    {stats.upcoming.length===0?<p>Nenhuma entrada confirmada ou aprovada nesta consulta.</p>:<ul>{stats.upcoming.map(x=><li key={x.id}>{fmt(x.starts_at)} — {labels[x.status]||x.status}</li>)}</ul>}
   </section>
   <p>Este painel é somente de consulta. Aprovações e transições devem ser executadas pelas funções protegidas do banco após homologação.</p>
  </>}
 </main>;
}
