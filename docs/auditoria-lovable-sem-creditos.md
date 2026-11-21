# Auditoria de integração Lovable — 21/11/2026

## Origem
- GitHub original: `bertasipedro2-svg/pethinho-hotel`, branch `development`.
- Supabase existente: `pethinho-hotel-dev` (`kloldcefnpjqyadojpet`).
- Lovable: `a1a2c4ef-79ff-4af6-a55d-a14b46730deb`.
- **Lovable interrompido por falta de créditos**. Nenhuma nova geração deve ser solicitada.
- Lovable é um projeto distinto; não há evidência de sincronização bidirecional com o GitHub original.
- O Lovable aparece publicado publicamente; **isso não comprova conexão com o banco nem prontidão comercial**.

## Estrutura real verificada no Supabase
- `profiles`: `id,full_name,phone,created_at` (já existem; não criar novamente).
- `pets`: `id,owner_id,name,species,breed,birth_date,weight_kg,care_notes,created_at`.
- `services`: `id,name,description,price_cents,duration_minutes,active`. **Não existe coluna `price`**; calcular reais a partir de `price_cents/100`.
- `bookings`: `id,owner_id,pet_id,service_id,accommodation_id,starts_at,ends_at,status,notes,created_at`.
- Evitar SQL genérico sugerido em `docs/sql-pendente.md` do Lovable: ele propõe adicionar `pets.birth_date`, que **já existe**; também supõe coluna de preço diferente.

## Bloqueios operacionais
1. Configurar a URL do projeto Supabase e **somente** chave publicável no frontend do Lovable; jamais service_role.
2. Confirmar que autenticação, leituras e RPCs operam contra o projeto existente.
3. Validar políticas RLS com usuários de teste distintos e perfis tutor/equipe.
4. Confirmar fluxo `approved -> confirmed` sem registrar pagamento fictício.
5. Testar login, cadastro pet, solicitação, aprovação, conflitos de acomodação, cancelamento, check-in e check-out.
6. Verificar build e testes automatizados; sem evidência, não declarar homologado.
7. Serviços permanecem inativos até aprovação de valores e regras comerciais.

## Regras de custo e segurança
- Orçamento R$ 0; não consumir créditos do Lovable nem contratar plano.
- Não alterar `main`, não criar banco paralelo, não ativar reservas reais sem validação.
- Continuar desenvolvimento gratuito via GitHub e Supabase e registrar testes reais.
