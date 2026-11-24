# Integração PETHINHO HOTEL

## Auditoria
- pethinho-hotel/development: Next.js 15, React 19, cliente Supabase por NEXT_PUBLIC_SUPABASE_URL e NEXT_PUBLIC_SUPABASE_ANON_KEY.
- pethinho-paws-and-pillow: TanStack Start/Vite, React 19.2, Vitest, Tailwind. README identifica projeto Lovable a1a2c4ef-79ff-4af6-a55d-a14b46730deb e declara sincronização com main. Sincronização efetiva ainda não testada.
- src/lib/supabase.ts no segundo repo aponta por padrão para kloldcefnpjqyadojpet.supabase.co, com possibilidade de override VITE. Não comprova conexão em runtime.
- Banco consultado: profiles 2, pets 0, services 3, accommodations 0, bookings 0, staff_roles 0. RLS ativo nas seis tabelas.

## Plano
1. Preservar ambos os repositórios e main. Não fazer merge direto entre frameworks.
2. Inventariar rotas e RPCs e comparar tipos com schema real; usar interface TanStack como candidata e portar regras e testes Next.js de forma seletiva.
3. Trabalhar em branch isolada no segundo repo somente após verificar efeito da sincronização Lovable. Não publicar.
4. Corrigir pico de ocupação e validar concorrência no banco dev, mantendo bloqueio de reservas reais.
5. Validar login, RLS, cadastro, agenda, administração, check-in/out e financeiro com dados simulados. Executar build e Vitest.
6. Verificar variáveis de ambiente efetivas, sem segredos no GitHub. Não usar service_role no cliente.
7. Homologar no iPhone e solicitar autorização separada para publicação.

Sem cobranças, sem consumo de créditos Lovable nesta auditoria, sem mudanças no banco ou main. Não afirmar integração funcional até testes ponta a ponta.
