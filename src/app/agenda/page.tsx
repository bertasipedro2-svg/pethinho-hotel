"use client";
import {useEffect,useState} from "react";
import {getSupabase} from "@/lib/supabase";
type Booking={id:string;starts_at:string;ends_at:string;status:string};
const statusLabel:Record<string,string>={pending:"Aguardando análise",approved:"Aprovada",confirmed:"Confirmada",checked_in:"Check-in realizado",checked_out:"Check-out realizado",completed:"Concluída",cancelled:"Cancelada",no_show:"Não compareceu"};
function localDate(d:Date){const year=d.getFullYear();const month=String(d.getMonth()+1).padStart(2,"0");const day=String(d.getDate()).padStart(2,"0");return `${year}-${month}-${day}`;}
function dayBounds(date:string){const [y,m,d]=date.split("-").map(Number);if(!y||!m||!d)return null;const start=new Date(y,m-1,d);if(start.getFullYear()!==y||start.getMonth()!==m-1||start.getDate()!==d)return null;const end=new Date(y,m-1,d+1);return {start:start.toISOString(),end:end.toISOString()};}
export default function Agenda(){
 const[items,setItems]=useState<Booking[]>([]);
 const[message,setMessage]=useState("Carregando...");
 const[date,setDate]=useState(()=>localDate(new Date()));
 const[loading,setLoading]=useState(true);
 useEffect(()=>{
  let cancelled=false;
  async function load(){
   setLoading(true);setItems([]);setMessage("Carregando...");
   try{
    const bounds=dayBounds(date);if(!bounds)throw new Error("Selecione uma data válida.");
    const db=getSupabase();
    const{data:{user},error:authError}=await db.auth.getUser();
    if(authError)throw authError;
    if(!user){if(!cancelled)setMessage("Faça login para visualizar suas reservas.");return;}
    const{data,error}=await db.from("bookings").select("id,starts_at,ends_at,status").eq("owner_id",user.id).lt("starts_at",bounds.end).gt("ends_at",bounds.start).order("starts_at").limit(100);
    if(error)throw error;
    if(!cancelled){setItems(data||[]);setMessage("");}
   }catch(e){if(!cancelled)setMessage(e instanceof Error?e.message:"Erro ao carregar agenda");}
   finally{if(!cancelled)setLoading(false);}
  }
  void load();
  return()=>{cancelled=true;};
 },[date]);
 return <main><h1>Agenda de reservas</h1><p>Exibe somente as reservas permitidas para sua conta.</p>
 <label>Dia <input type="date" value={date} onChange={e=>setDate(e.target.value)}/></label>
 <p role="status" aria-live="polite">{message}</p>
 {!loading&&!message&&<section className="card">{items.length===0?<p>Sem reservas visíveis neste dia.</p>:items.map(b=><article key={b.id}><strong>{statusLabel[b.status]||b.status}</strong><p>{new Date(b.starts_at).toLocaleString("pt-BR")} — {new Date(b.ends_at).toLocaleString("pt-BR")}</p><hr/></article>)}</section>}
 </main>;
}
