"use client";
import {useEffect,useState} from "react";
import type {FormEvent} from "react";
import {getSupabase} from "@/lib/supabase";
import type {User} from "@supabase/supabase-js";
type Pet={id:string;name:string;species:string;breed:string|null};
type Service={id:string;name:string};
export default function MinhaConta(){
 const[user,setUser]=useState<User|null>(null);
 const[pets,setPets]=useState<Pet[]>([]);const[services,setServices]=useState<Service[]>([]);
 const[petName,setPetName]=useState("");const[breed,setBreed]=useState("");
 const[petId,setPetId]=useState("");const[serviceId,setServiceId]=useState("");
 const[start,setStart]=useState("");const[end,setEnd]=useState("");
 const[msg,setMsg]=useState("");const[loading,setLoading]=useState(true);const[busy,setBusy]=useState(false);
 async function refresh(){
  const db=getSupabase();const {data:{user:u},error:authError}=await db.auth.getUser();
  if(authError)throw authError;
  setUser(u);
  if(u){
   const[p,s]=await Promise.all([
    db.from("pets").select("id,name,species,breed").eq("owner_id",u.id).order("name"),
    db.from("services").select("id,name").eq("active",true)
   ]);
   if(p.error||s.error)throw p.error||s.error;
   setPets(p.data||[]);setServices(s.data||[]);
  }else{setPets([]);setServices([])}
  setLoading(false);
 }
 useEffect(()=>{refresh().catch(e=>{setMsg(e instanceof Error?e.message:String(e));setLoading(false)})},[]);
 async function addPet(e:FormEvent){
  e.preventDefault();if(busy||!user)return;
  const name=petName.trim();if(!name){setMsg("Informe o nome do pet.");return}
  setBusy(true);setMsg("");
  try{
   const{error}=await getSupabase().from("pets").insert({owner_id:user.id,name,species:"dog",breed:breed.trim()||null});
   if(error)throw error;setPetName("");setBreed("");await refresh();setMsg("Pet cadastrado.");
  }catch(e){setMsg(e instanceof Error?e.message:"Falha ao cadastrar pet.")}finally{setBusy(false)}
 }
 async function book(e:FormEvent){
  e.preventDefault();if(busy||!user)return;
  if(!pets.some(p=>p.id===petId)||!services.some(s=>s.id===serviceId)){setMsg("Selecione um pet e um serviço disponíveis.");return}
  const startsAt=new Date(start),endsAt=new Date(end);
  if(!Number.isFinite(startsAt.getTime())||!Number.isFinite(endsAt.getTime())){setMsg("Informe datas válidas.");return}
  if(startsAt.getTime()<=Date.now()){setMsg("A entrada precisa ser no futuro.");return}
  if(endsAt.getTime()<=startsAt.getTime()){setMsg("A saída deve ser posterior à entrada.");return}
  setBusy(true);setMsg("");
  try{
   const{error}=await getSupabase().rpc("request_booking",{p_pet_id:petId,p_service_id:serviceId,p_starts_at:startsAt.toISOString(),p_ends_at:endsAt.toISOString(),p_notes:null});
   if(error)throw error;
   setStart("");setEnd("");setMsg("Solicitação enviada. Aguarde a confirmação do hotel.");
  }catch(e){setMsg(e instanceof Error?e.message:"Não foi possível solicitar a reserva.")}finally{setBusy(false)}
 }
 if(loading)return <main><p role="status">Carregando...</p></main>;
 if(!user)return <main><h1>Área do tutor</h1><a href="/entrar">Faça login para continuar</a><p role="alert">{msg}</p></main>;
 return <main><h1>Minha conta</h1><p>{user.email}</p>
 <button disabled={busy} onClick={async()=>{await getSupabase().auth.signOut();window.location.href="/entrar"}}>Sair</button>
 <section className="card"><h2>Meus pets</h2>{pets.length===0&&<p>Nenhum pet cadastrado.</p>}
 {pets.map(p=><p key={p.id}>🐾 {p.name} {p.breed?"— "+p.breed:""}</p>)}
 <form onSubmit={addPet}><label>Nome do pet<input required maxLength={100} value={petName} onChange={e=>setPetName(e.target.value)}/></label>
 <label>Raça (opcional)<input maxLength={100} value={breed} onChange={e=>setBreed(e.target.value)}/></label>
 <button disabled={busy}>{busy?"Aguarde...":"Cadastrar pet"}</button></form></section>
 <section className="card"><h2>Solicitar agendamento</h2>
 {services.length===0?<p>Os agendamentos ainda não foram liberados pelo hotel.</p>:
 <form onSubmit={book}><label>Pet<select required value={petId} onChange={e=>setPetId(e.target.value)}><option value="">Selecione</option>{pets.map(p=><option key={p.id} value={p.id}>{p.name}</option>)}</select></label>
 <label>Serviço<select required value={serviceId} onChange={e=>setServiceId(e.target.value)}><option value="">Selecione</option>{services.map(s=><option key={s.id} value={s.id}>{s.name}</option>)}</select></label>
 <label>Entrada<input type="datetime-local" required value={start} onChange={e=>setStart(e.target.value)}/></label>
 <label>Saída<input type="datetime-local" required value={end} onChange={e=>setEnd(e.target.value)}/></label>
 <button disabled={busy||pets.length===0}>{busy?"Enviando...":"Enviar solicitação"}</button></form>}</section>
 <p role="status" aria-live="polite">{msg}</p></main>
}
