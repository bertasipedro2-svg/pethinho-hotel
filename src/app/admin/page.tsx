"use client";
import {useEffect,useState} from "react";
import {getSupabase} from "@/lib/supabase";
type Booking={id:string;starts_at:string;ends_at:string;status:string};
export default function Admin(){const[allowed,setAllowed]=useState(false);const[rows,setRows]=useState<Booking[]>([]);const[msg,setMsg]=useState("Verificando permissões...");
 useEffect(()=>{async function load(){try{const db=getSupabase();const{data:{user}}=await db.auth.getUser();if(!user){setMsg("Faça login.");return}const{data:role,error:roleError}=await db.from("staff_roles").select("role").eq("user_id",user.id).maybeSingle();if(roleError)throw roleError;if(!role){setMsg("Acesso restrito à equipe autorizada.");return}setAllowed(true);const{data,error}=await db.from("bookings").select("id,starts_at,ends_at,status").order("starts_at",{ascending:true}).limit(100);if(error)throw error;setRows(data||[]);setMsg("");}catch(e){setMsg(e instanceof Error?e.message:"Erro de consulta")}}load()},[]);
 return <main><h1>Painel administrativo</h1>{!allowed?<p>{msg}</p>:<section className="card"><h2>Reservas</h2><p>Visão inicial de solicitações. Aprovações e disponibilidade ainda estão em desenvolvimento.</p>{rows.map(x=><p key={x.id}>{new Date(x.starts_at).toLocaleString("pt-BR")} — {x.status}</p>)}{rows.length===0&&<p>Nenhuma reserva encontrada.</p>}</section>}</main>}
