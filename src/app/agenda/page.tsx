"use client";
import {useEffect,useState} from "react";
import {getSupabase} from "@/lib/supabase";
type Booking={id:string;starts_at:string;ends_at:string;status:string};
const statusLabel:Record<string,string>={pending:"Aguardando análise",approved:"Aprovada",confirmed:"Confirmada",checked_in:"Check-in realizado",checked_out:"Check-out realizado",completed:"Concluída",cancelled:"Cancelada",no_show:"Não compareceu"};
function localDate(d:Date){return new Intl.DateTimeFormat("sv-SE",{timeZone:"America/Sao_Paulo",year:"numeric",month:"2-digit",day:"2-digit"}).format(d);}
// A agenda utiliza o dia civil do estabelecimento (São Paulo), não o fuso do dispositivo.
function saoPauloMidnight(year:number,month:number,day:number){
 const midnightUtc=Date.UTC(year,month-1,day);
 let instant=midnightUtc;
 const formatter=new Intl.DateTimeFormat("en-US",{timeZone:"America/Sao_Paulo",timeZoneName:"shortOffset"});
 for(let i=0;i<3;i++){
  const label=formatter.formatToParts(new Date(instant)).find(part=>part.type==="timeZoneName")?.value||"";
  const match=/^GMT([+-])(\d{1,2})(?::(\d{2}))?$/.exec(label);
  if(!match)throw new Error("Fuso horário indisponível.");
  const offset=(match[1]==="+"?1:-1)*(Number(match[2])*60+Number(match[3]||0));
  const next=midnightUtc-offset*60000;
  if(next===instant)break;
  instant=next;
 }
 return new Date(instant).toISOString();
}
function dayBounds(date:string){
 if(!/^\d{4}-\d{2}-\d{2}$/.test(date))return null;
 const [y,m,d]=date.split("-").map(Number);
 const check=new Date(Date.UTC(y,m-1,d));
 if(check.getUTCFullYear()!==y||check.getUTCMonth()!==m-1||check.getUTCDate()!==d)return null;
 return {start:saoPauloMidnight(y,m,d),end:saoPauloMidnight(y,m,d+1)};
}
export default function Agenda(){
 const[items,setItems]=useState<Booking[]>([]);
 const[message,setMessage]=useState("Carregando...");
 const[date,setDate]=useState(()=>localDate(new Date()));
 const[loading,setLoading]=useState(true);
 const[page,setPage]=useState(0);
 const[refreshKey,setRefreshKey]=useState(0);
 const[total,setTotal]=useState(0);
 const pageSize=50;
 useEffect(()=>{
  let cancelled=false;
  async function load(){
   setLoading(true);setItems([]);setTotal(0);setMessage("Carregando...");
   try{
    const bounds=dayBounds(date);if(!bounds)throw new Error("Selecione uma data válida.");
    const db=getSupabase();
    const{data:{user},error:authError}=await db.auth.getUser();
    if(authError)throw authError;
    if(!user){if(!cancelled)setMessage("Faça login para visualizar suas reservas.");return;}
    const{data,error,count}=await db.from("bookings").select("id,starts_at,ends_at,status",{count:"exact"}).eq("owner_id",user.id).lt("starts_at",bounds.end).gt("ends_at",bounds.start).order("starts_at",{ascending:true}).order("id",{ascending:true}).range(page*pageSize,(page+1)*pageSize-1);
    if(error)throw error;
    if(!cancelled){
     const resultTotal=count||0;
     // Se uma reserva foi removida, a página atual pode não existir mais.
     // Retorne à última página válida em vez de exibir uma lista vazia enganosa.
     if(page>0&&page*pageSize>=resultTotal){setPage(Math.max(0,Math.ceil(resultTotal/pageSize)-1));return;}
     setItems(data||[]);setTotal(resultTotal);setMessage("");
    }
   }catch(e){
    // Não exibir detalhes internos do banco ou da autenticação ao cliente.
    console.error("Falha ao carregar agenda",e);
    if(!cancelled)setMessage(e instanceof Error&&e.message==="Selecione uma data válida."?e.message:"Não foi possível carregar suas reservas. Tente atualizar.");
   }
   finally{if(!cancelled)setLoading(false);}
  }
  void load();
  return()=>{cancelled=true;};
 },[date,page,refreshKey]);
 return <main><h1>Agenda de reservas</h1><p>Exibe somente as reservas permitidas para sua conta.</p>
 <label>Dia <input type="date" value={date} onChange={e=>{setDate(e.target.value);setPage(0);}}/></label>
 <button type="button" disabled={loading} onClick={()=>setRefreshKey(k=>k+1)} aria-label="Atualizar reservas da agenda">Atualizar reservas</button>
 <p role="status" aria-live="polite">{message}</p>
 {!loading&&!message&&<p>{total} reserva(s) neste dia. Página {page+1} de {Math.max(1,Math.ceil(total/pageSize))}.</p>}
 {!loading&&!message&&<section className="card">{items.length===0?<p>Sem reservas visíveis neste dia.</p>:items.map(b=><article key={b.id}><strong>{statusLabel[b.status]||b.status}</strong><p>{new Date(b.starts_at).toLocaleString("pt-BR")} — {new Date(b.ends_at).toLocaleString("pt-BR")}</p><hr/></article>)}</section>}
 {!loading&&!message&&total>pageSize&&<nav aria-label="Paginação da agenda"><button type="button" disabled={page===0} onClick={()=>setPage(p=>Math.max(0,p-1))}>Anterior</button> <button type="button" disabled={(page+1)*pageSize>=total} onClick={()=>setPage(p=>p+1)}>Próxima</button></nav>}
 </main>;
}
