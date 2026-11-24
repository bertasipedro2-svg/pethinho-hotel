# Pethinho Hotel — Final Execution Lab

Ambiente: Supabase `pethinho-hotel-dev` e projeto Lovable existente. Os testes usam dados sintéticos. O site publicado permanece na versão anterior.

| Fase | Evidência | Pendente |
| --- | --- | --- |
| 1. Banco | Pico de ocupação aplicado em `20261124013915`. PostgreSQL descartável verificou intervalos adjacentes, capacidade, concorrência com espera real por lock, exclusão operacional por pet e repetição concorrente da mesma solicitação. | Aprovação e confirmação de acomodações compartilhadas continuam desabilitadas no RPC da equipe. Validar a regra comercial antes de ativá-las. |
| 2. Segurança | `20261124014026` revoga acesso anônimo aos helpers de equipe e chamadas diretas a funções de trigger. Testes locais com anônimo, tutor, equipe e administrador passaram. HTTP anônimo do helper de equipe retornou 401. | Revisar os alertas de extensão no schema público e proteção contra senhas vazadas. Revalidar roles com sessões hospedadas. |
| 3. Integração | URL e chave publicável do código coincidem com o Supabase autorizado. Auth settings retornou 200 e consulta anônima de reservas retornou zero linhas. Lovable Cloud segue desativado. | Sessões autenticadas e todas as APIs da prévia hospedada ainda precisam de homologação. |
| 4. Administração | Teste SQL dos RPCs de aprovação, confirmação, check-in, check-out e conclusão. Melhorias da agenda e disponibilidade na branch da interface. | Edição administrativa de cadastros. A branch da interface inclui consulta de tutores e pets, criação de acomodações individuais e criação de serviços. |
| 5. Financeiro | `20261124014424` instala lançamentos manuais, RLS de admin e baixa única. Verificado em PostgreSQL, inclusive bloqueio de edição de valor. O ambiente remoto permanece sem lançamentos. | Homologar com responsável financeiro e confirmar critérios de relatório por competência e fluxo de caixa. |
| 6. Design | Navegação da equipe adaptada a telas estreitas e estados de erro mais claros na disponibilidade. | Revisão visual completa das telas administrativas restantes. |
| 7. Mobile | Chromium com perfil iPhone 13 passou no fluxo local com APIs interceptadas. | Safari iOS físico e APIs autenticadas hospedadas. |
| 8. Release | SQL e reversões versionados. TypeScript, 29 testes, build e lint das mudanças passaram. Lint global ainda aponta problemas preexistentes. | Homologação comercial, operação real e autorização de lançamento. |

## Reproduzir

Com Node.js e `embedded-postgres@18.6.0-beta.19` disponíveis, rode `node sql/tests/capacity-concurrency.mjs`. O script abre três conexões a um PostgreSQL local descartável, usando loopback e uma senha temporária. Use `PETHINHO_TEST_PG_PORT` se a porta 55433 estiver ocupada.

A segunda conta de tutor não enxerga as reservas da primeira no teste da política de reservas. A aplicação não cria cobranças nem classifica estimativas como receitas recebidas. No caixa, o administrador registra a saída ou o recebimento manualmente, após conferi-lo.

## Restauração e branches

Os SQLs em `sql/rollback/` restauram as funções e os grants anteriores ou suspendem o acesso ao caixa sem apagar lançamentos. Os testes capturam as funções operacionais anteriores em um fixture de referência. O código da interface fica separado em [lab/pethinho-final-app](https://github.com/bertasipedro2-svg/pethinho-paws-and-pillow/tree/lab/pethinho-final-app). Não houve merge na main vinculada ao Lovable nem publicação.

- Banco e testes SQL: commit `4e571ae`.
- Interface e evidências móveis: commit `53c55d8`, [PR da interface](https://github.com/bertasipedro2-svg/pethinho-paws-and-pillow/pull/1).
