"use client";
import {useEffect,useMemo,useState} from "react";
import {getSupabase} from "@/lib/supabase";

type Booking={booking_id:string;starts_at:string;ends_at:string;status:string;pet_name:string;accommodation_name:string|null};
const fmt=(date:string)=>new Date(date).toLocaleString("pt-BR",{dateStyle:"short",timeStyle:"short"});
const labels:Record<string,string>={pending:"Pendente",approved:"Aprovada",confirmed:"Confirmada",checked_in:"Hospedado",checked_out:"Check-out",completed:"Concluída",cancelled:"Cancelada",no_show:"Não compareceu"};
export default function Admin(){
 const[allowed,setAllowed]=useState(false),[rows,setRows]=useState<Booking[]>([]);
 const[loading,setLoading]=useState(true),[msg,setMsg]=useState("Verificando permissões...");
 const[refresh,setRefresh]=useState(0),[truncated,setTruncated]=useState(false);
 const[readiness,setReadiness]=useState<{accommodations:number;services:number}|null>(null);
 // Revalidar o acesso quando a sessão muda (inclusive logout em outra aba).
 useEffect(()=>{
  const db=getSupabase();
  const {data:{subscription}}=db.auth.onAuthStateChange(event=>{
   if(event==="SIGNED_IN"||event==="SIGNED_OUT"||event==="USER_UPDATED"){
    setAllowed(false);
    setRows([]);
    setReadiness(null);
    setLoading(true);
    setRefresh(n=>n+1);
   }
  });
  // Ao retornar à aba, revalidar sessão e função antes de mostrar dados antigos.
  const revalidate=()=>{
   if(document.visibilityState!=="visible")return;
   setAllowed(false);
   setRows([]);
   setReadiness(null);
   setLoading(true);
   setRefresh(n=>n+1);
  };
  document.addEventListener("visibilitychange",revalidate);
  return()=>{
   subscription.unsubscribe();
   document.removeEventListener("visibilitychange",revalidate);
  };
 },[]);
 useEffect(()=>{
  let active=true;
  async function load(){
   if(active){setLoading(true);setAllowed(false);setRows([]);setReadiness(null);setTruncated(false);setMsg("Verificando permissões...");}
   try{
    const db=getSupabase();
    const{data:{user},error:authError}=await db.auth.getUser();
    if(authError)throw authError;
    if(!user){if(active)setMsg("Faça login para acessar o painel.");return}
    const{data:role,error:roleError}=await db.from("staff_roles").select("role").eq("user_id",user.id).maybeSingle();
    if(roleError)throw roleError;
    if(!role||!["admin","staff"].includes(role.role)){if(active)setMsg("Acesso restrito à equipe autorizada.");return}
    // Consultas independentes de leitura: nenhuma reserva é criada ou ativada.
    const [accommodationsResult,servicesResult]=await Promise.all([
     db.from("accommodations").select("id",{count:"exact",head:true}).eq("active",true),
     db.from("services").select("id",{count:"exact",head:true}).eq("active",true),
    ]);
    if(accommodationsResult.error)throw accommodationsResult.error;
    if(servicesResult.error)throw servicesResult.error;
    const all:Booking[]=[];
    const pageSize=500;
    let hasMore=true;
    while(hasMore&&all.length<10000){
     const{data,error}=await db.from("booking_calendar").select("booking_id,starts_at,ends_at,status,pet_name,accommodation_name" ).order("starts_at",{ascending:false}).order("booking_id",{ascending:false}).range(all.length,all.length+pageSize-1);
     if(error)throw error;
     all.push(...(data||[]));
     hasMore=(data||[]).length===pageSize;
    }
    // A sessão ou a função da equipe pode ter mudado durante a paginação.
    // Nunca exibir dados obtidos com uma autorização que já não é válida.
    if(!active)return;
    const {data:{user:currentUser},error:currentAuthError}=await db.auth.getUser();
    if(currentAuthError)throw currentAuthError;
    if(!currentUser||currentUser.id!==user.id)throw new Error("Sessão alterada. Atualize o painel.");
    const {data:currentRole,error:currentRoleError}=await db.from("staff_roles").select("role").eq("user_id",currentUser.id).maybeSingle();
    if(currentRoleError)throw currentRoleError;
    if(!currentRole||!["admin","staff"].includes(currentRole.role))throw new Error("Acesso administrativo revogado.");
    if(active){setAllowed(true);setRows(all);setTruncated(hasMore);setReadiness({accommodations:accommodationsResult.count??0,services:servicesResult.count??0});setMsg("");}
   }catch(e){if(active){setAllowed(false);setReadiness(null);setMsg(e instanceof Error?e.message:"Falha ao consultar reservas.");}}
   finally{if(active)setLoading(false)}
  }
  void load();
  return()=>{active=false};
 },[refresh]);
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
   {readiness&&<section className="card" aria-labelledby="readiness"><h2 id="readiness">Prontidão operacional</h2>
    <p>Acomodações ativas: {readiness.accommodations}. Serviços ativos: {readiness.services}.</p>
    {(readiness.accommodations===0||readiness.services===0)&&<p role="alert">Homologação pendente: não há {readiness.accommodations===0?"acomodações ativas":"capacidade validada"}{readiness.services===0?" e serviços ativos":""}. Não liberar reservas comerciais.</p>}
    <p>Estes indicadores não comprovam capacidade disponível nem autorização para operar; validar conflitos e permissões antes da liberação.</p>
   </section>}
   <p role="status">Resumo de {rows.length} reservas acessíveis à equipe. Dados sujeitos às permissões do Supabase; não é um relatório financeiro.</p>
   {truncated&&<p role="alert">Limite de 10.000 reservas atingido. Os totais podem estar incompletos; exporte os dados para uma apuração completa.</p>}
   <button type="button" onClick={()=>{setLoading(true);setRefresh(n=>n+1)}}>Atualizar dados</button>
   <section className="card" aria-labelledby="summary"><h2 id="summary">Resumo por situação</h2>
    <ul>{Object.entries(labels).map(([key,label])=><li key={key}>{label}: {stats.counts[key]||0}</li>)}</ul>
   </section>
   <section className="card" aria-labelledby="staying"><h2 id="staying">Hospedagens em andamento ({stats.staying.length})</h2>
    {stats.staying.length===0?<p>Nenhum check-in em andamento nesta consulta.</p>:<ul>{stats.staying.map(x=><li key={x.booking_id}>{x.pet_name} — {x.accommodation_name||"Acomodação não atribuída"} — Entrada {fmt(x.starts_at)} — saída prevista {fmt(x.ends_at)}</li>)}</ul>}
   </section>
   <section className="card" aria-labelledby="upcoming"><h2 id="upcoming">Próximas entradas — 7 dias ({stats.upcoming.length})</h2>
    {stats.upcoming.length===0?<p>Nenhuma entrada confirmada ou aprovada nesta consulta.</p>:<ul>{stats.upcoming.map(x=><li key={x.booking_id}>{x.pet_name} — {x.accommodation_name||"Acomodação não atribuída"} — {fmt(x.starts_at)} — {labels[x.status]||x.status}</li>)}</ul>}
   </section>
   <p>Este painel é somente de consulta. Aprovações e transições devem ser executadas pelas funções protegidas do banco após homologação.</p>
  </>}
 </main>;
}
